using NukeAssalt.Tools.Config;

namespace NukeAssalt.Specs;

public sealed class MatchRoundFlowTests
{
    private readonly string _repoRoot = RepositoryRoot.Find();

    [Fact]
    public void Match_requires_minimum_players_before_start()
    {
        var matchConfig = LoadMatchConfig();
        var flow = new MatchFlowSimulation(matchConfig.Format.RoundsToWin, matchConfig.Format.SwapAfterRounds);

        var insufficientPlayerCount = matchConfig.Format.MinimumPlayersToStart - 1;

        Assert.False(flow.CanStartMatch(insufficientPlayerCount, matchConfig.Format.MinimumPlayersToStart));
        Assert.True(flow.CanStartMatch(matchConfig.Format.MinimumPlayersToStart, matchConfig.Format.MinimumPlayersToStart));
    }

    [Fact]
    public void Round_does_not_advance_before_previous_round_completes()
    {
        var matchConfig = LoadMatchConfig();
        var flow = new MatchFlowSimulation(matchConfig.Format.RoundsToWin, matchConfig.Format.SwapAfterRounds);

        flow.StartMatch(matchConfig.Format.MinimumPlayersToStart);
        flow.BeginLiveRound();
        flow.ResolveRound("Attackers");

        Assert.Equal(1, flow.CurrentRoundNumber);
        Assert.Equal(MatchFlowSimulation.Phases.PostRound, flow.Phase);

        flow.AdvanceAfterPostRound();

        Assert.Equal(2, flow.CurrentRoundNumber);
        Assert.Equal(MatchFlowSimulation.Phases.BuyPhase, flow.Phase);
    }

    [Fact]
    public void Round_timeout_before_plant_benefits_defenders()
    {
        var outcome = MatchFlowSimulation.DetermineWinner(attackersAliveCount: 2, defendersAliveCount: 1, liveTimerExpired: true);

        Assert.Equal("Defenders", outcome.Winner);
        Assert.Equal("Timeout", outcome.Reason);
    }

    [Fact]
    public void Invalid_match_round_transitions_are_rejected()
    {
        var matchConfig = LoadMatchConfig();
        var flow = new MatchFlowSimulation(matchConfig.Format.RoundsToWin, matchConfig.Format.SwapAfterRounds);

        flow.StartMatch(matchConfig.Format.MinimumPlayersToStart);

        Assert.Throws<InvalidOperationException>(() => flow.AdvanceAfterPostRound());

        flow.BeginLiveRound();

        Assert.Throws<InvalidOperationException>(() => flow.BeginLiveRound());
    }

    [Fact]
    public void Side_swap_occurs_exactly_after_configured_round()
    {
        var matchConfig = LoadMatchConfig();
        var flow = new MatchFlowSimulation(matchConfig.Format.RoundsToWin, matchConfig.Format.SwapAfterRounds);

        flow.StartMatch(matchConfig.Format.MinimumPlayersToStart);

        for (var round = 1; round < matchConfig.Format.SwapAfterRounds; round += 1)
        {
            flow.BeginLiveRound();
            flow.ResolveRound("Attackers");
            flow.AdvanceAfterPostRound();
            Assert.False(flow.SidesSwapped);
        }

        flow.BeginLiveRound();
        flow.ResolveRound("Defenders");
        flow.AdvanceAfterPostRound();

        Assert.True(flow.SidesSwapped);
        Assert.Equal(matchConfig.Format.SwapAfterRounds + 1, flow.CurrentRoundNumber);
    }

    [Fact]
    public void Match_winner_is_declared_on_round_threshold()
    {
        var matchConfig = LoadMatchConfig();
        var flow = new MatchFlowSimulation(matchConfig.Format.RoundsToWin, matchConfig.Format.SwapAfterRounds);

        flow.StartMatch(matchConfig.Format.MinimumPlayersToStart);

        for (var round = 1; round < matchConfig.Format.RoundsToWin; round += 1)
        {
            flow.BeginLiveRound();
            flow.ResolveRound("Attackers");
            flow.AdvanceAfterPostRound();
        }

        flow.BeginLiveRound();
        flow.ResolveRound("Attackers");

        Assert.Equal("Attackers", flow.Winner);
        Assert.Equal(MatchFlowSimulation.Phases.MatchComplete, flow.Phase);
        Assert.Equal(matchConfig.Format.RoundsToWin, flow.AttackersScore);
    }

    private MatchConfigDocument LoadMatchConfig()
    {
        return ConfigLoader.LoadBundle(Path.Combine(_repoRoot, "data", "config")).Match;
    }

    private sealed class MatchFlowSimulation
    {
        public static class Phases
        {
            public const string WaitingForPlayers = "WaitingForPlayers";
            public const string BuyPhase = "BuyPhase";
            public const string LiveRound = "LiveRound";
            public const string PostRound = "PostRound";
            public const string SideSwap = "SideSwap";
            public const string MatchComplete = "MatchComplete";
        }

        private readonly int _roundsToWin;
        private readonly int _swapAfterRounds;

        public MatchFlowSimulation(int roundsToWin, int swapAfterRounds)
        {
            _roundsToWin = roundsToWin;
            _swapAfterRounds = swapAfterRounds;
            Phase = Phases.WaitingForPlayers;
        }

        public int AttackersScore { get; private set; }
        public int CurrentRoundNumber { get; private set; }
        public int DefendersScore { get; private set; }
        public string Phase { get; private set; }
        public int RoundsCompleted { get; private set; }
        public bool SidesSwapped { get; private set; }
        public string? Winner { get; private set; }

        public bool CanStartMatch(int playerCount, int minimumPlayersToStart)
        {
            return playerCount >= minimumPlayersToStart;
        }

        public void StartMatch(int playerCount)
        {
            if (playerCount <= 0)
            {
                throw new ArgumentOutOfRangeException(nameof(playerCount));
            }

            AttackersScore = 0;
            CurrentRoundNumber = 1;
            DefendersScore = 0;
            Phase = Phases.BuyPhase;
            RoundsCompleted = 0;
            SidesSwapped = false;
            Winner = null;
        }

        public void ResolveRound(string winnerTeam)
        {
            if (Phase is not Phases.LiveRound)
            {
                throw new InvalidOperationException("A round can only resolve from the live phase.");
            }

            if (winnerTeam == "Attackers")
            {
                AttackersScore += 1;
            }
            else if (winnerTeam == "Defenders")
            {
                DefendersScore += 1;
            }
            else
            {
                throw new ArgumentOutOfRangeException(nameof(winnerTeam));
            }

            RoundsCompleted += 1;

            if (AttackersScore >= _roundsToWin || DefendersScore >= _roundsToWin)
            {
                Winner = winnerTeam;
                Phase = Phases.MatchComplete;
                return;
            }

            Phase = !SidesSwapped && RoundsCompleted == _swapAfterRounds
                ? Phases.SideSwap
                : Phases.PostRound;
        }

        public void BeginLiveRound()
        {
            if (Phase is not Phases.BuyPhase)
            {
                throw new InvalidOperationException("The live round can only start from buy phase.");
            }

            Phase = Phases.LiveRound;
        }

        public void AdvanceAfterPostRound()
        {
            if (Phase == Phases.MatchComplete)
            {
                return;
            }

            if (Phase is not Phases.PostRound and not Phases.SideSwap)
            {
                throw new InvalidOperationException("Cannot advance before the round is resolved.");
            }

            if (!SidesSwapped && RoundsCompleted == _swapAfterRounds)
            {
                SidesSwapped = true;
            }

            CurrentRoundNumber = RoundsCompleted + 1;
            Phase = Phases.BuyPhase;
        }

        public static (string? Winner, string? Reason) DetermineWinner(int attackersAliveCount, int defendersAliveCount, bool liveTimerExpired)
        {
            if (attackersAliveCount <= 0 && defendersAliveCount > 0)
            {
                return ("Defenders", "Elimination");
            }

            if (defendersAliveCount <= 0 && attackersAliveCount > 0)
            {
                return ("Attackers", "Elimination");
            }

            if (attackersAliveCount <= 0 && defendersAliveCount <= 0)
            {
                return ("Defenders", "Elimination");
            }

            if (liveTimerExpired)
            {
                return ("Defenders", "Timeout");
            }

            return (null, null);
        }
    }
}
