// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title Decentralized Voting System
/// @author Wraptron LLP
/// @notice Allows an admin to register candidates and voters to cast votes

contract Voting {
    // ─── Structs ───────────────────────────────────────────────────────────────

    struct Candidate {
        uint256 id;
        string name;
        string party;
        uint256 voteCount;
        bool exists;
    }

    // ─── State Variables ───────────────────────────────────────────────────────

    address public admin;
    bool public votingOpen;

    uint256 private candidateCount;

    mapping(uint256 => Candidate) public candidates; // candidateId => Candidate
    mapping(address => bool) public hasVoted; // voter => voted?
    mapping(address => uint256) public voterChoice; // voter => candidateId

    uint256[] private candidateIds;

    // ─── Events ────────────────────────────────────────────────────────────────

    event CandidateAdded(uint256 indexed id, string name, string party);
    event VoteCast(address indexed voter, uint256 indexed candidateId);
    event VotingStarted();
    event VotingEnded();

    // ─── Modifiers ─────────────────────────────────────────────────────────────

    modifier onlyAdmin() {
        require(msg.sender == admin, "Voting: caller is not admin");
        _;
    }

    modifier onlyWhenOpen() {
        require(votingOpen, "Voting: voting is not open");
        _;
    }

    modifier onlyWhenClosed() {
        require(!votingOpen, "Voting: voting is still open");
        _;
    }

    // ─── Constructor ───────────────────────────────────────────────────────────

    constructor() {
        admin = msg.sender;
        votingOpen = false;
    }

    // ─── Admin Functions ───────────────────────────────────────────────────────

    /// @notice Add a new candidate (only before or after voting, not during)
    /// @param _name  Full name of the candidate
    /// @param _party Political party or affiliation
    function addCandidate(
        string calldata _name,
        string calldata _party
    ) external onlyAdmin onlyWhenClosed {
        require(bytes(_name).length > 0, "Voting: name cannot be empty");
        require(bytes(_party).length > 0, "Voting: party cannot be empty");

        candidateCount++;
        uint256 newId = candidateCount;

        candidates[newId] = Candidate({
            id: newId,
            name: _name,
            party: _party,
            voteCount: 0,
            exists: true
        });

        candidateIds.push(newId);

        emit CandidateAdded(newId, _name, _party);
    }

    /// @notice Remove a candidate by ID (only when voting is closed)
    /// @param _id Candidate ID to remove
    function removeCandidate(uint256 _id) external onlyAdmin onlyWhenClosed {
        require(candidates[_id].exists, "Voting: candidate does not exist");

        delete candidates[_id];

        // Remove from candidateIds array
        for (uint256 i = 0; i < candidateIds.length; i++) {
            if (candidateIds[i] == _id) {
                candidateIds[i] = candidateIds[candidateIds.length - 1];
                candidateIds.pop();
                break;
            }
        }
    }

    /// @notice Open the voting session
    function startVoting() external onlyAdmin onlyWhenClosed {
        require(candidateIds.length >= 2, "Voting: need at least 2 candidates");
        votingOpen = true;
        emit VotingStarted();
    }

    /// @notice Close the voting session
    function endVoting() external onlyAdmin onlyWhenOpen {
        votingOpen = false;
        emit VotingEnded();
    }

    // ─── Voter Functions ───────────────────────────────────────────────────────

    /// @notice Cast a vote for a candidate
    /// @param _candidateId The ID of the candidate to vote for
    function castVote(uint256 _candidateId) external onlyWhenOpen {
        require(!hasVoted[msg.sender], "Voting: already voted");
        require(candidates[_candidateId].exists, "Voting: invalid candidate");

        hasVoted[msg.sender] = true;
        voterChoice[msg.sender] = _candidateId;
        candidates[_candidateId].voteCount++;

        emit VoteCast(msg.sender, _candidateId);
    }

    // ─── View Functions ────────────────────────────────────────────────────────

    /// @notice Get all candidate IDs
    // function getCandidateIds() external view returns (uint256[] memory) {
    //     return candidateIds;
    // }

    /// @notice Get details of a single candidate
    /// @param _id Candidate ID
    // function getCandidate(uint256 _id)
    //     external
    //     view
    //     returns (
    //         uint256 id,
    //         string memory name,
    //         string memory party,
    //         uint256 voteCount
    //     )
    // {
    //     require(candidates[_id].exists, "Voting: candidate does not exist");
    //     Candidate storage c = candidates[_id];
    //     return (c.id, c.name, c.party, c.voteCount);
    // }

    /// @notice Get all candidates with their vote counts
    function getAllCandidates() external view returns (Candidate[] memory) {
        Candidate[] memory list = new Candidate[](candidateIds.length);
        for (uint256 i = 0; i < candidateIds.length; i++) {
            list[i] = candidates[candidateIds[i]];
        }
        return list;
    }

    /// @notice Get total votes cast so far
    function totalVotes() external view returns (uint256 total) {
        for (uint256 i = 0; i < candidateIds.length; i++) {
            total += candidates[candidateIds[i]].voteCount;
        }
    }

    /// @notice Determine the winner (only after voting ends)
    /// @return winnerId   ID of the winning candidate
    /// @return winnerName Name of the winner
    /// @return winVotes   Vote count of the winner
    function getWinner()
        external
        view
        onlyWhenClosed
        returns (uint256 winnerId, string memory winnerName, uint256 winVotes)
    {
        require(candidateIds.length > 0, "Voting: no candidates");

        for (uint256 i = 0; i < candidateIds.length; i++) {
            Candidate storage c = candidates[candidateIds[i]];
            if (c.voteCount > winVotes) {
                winVotes = c.voteCount;
                winnerId = c.id;
                winnerName = c.name;
            }
        }
    }
}
