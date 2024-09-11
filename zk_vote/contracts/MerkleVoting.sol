// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract MerkleVoting {
    struct Voter {
        bool voted;
        bytes encryptedVote;
    }

    struct Candidate {
        string name;
        uint256 voteCount;
    }

    address public owner;
    string public electionName;
    mapping(address => Voter) public voters;
    Candidate[] public candidates;
    uint256 public totalVotes;
    bool public electionActive = false;
    uint256 public electionStart;
    uint256 public electionDuration;
    uint256 public electionEnd;
    bytes32 public merkleRoot;

    event VoteSubmitted(address voter, bytes encryptedVote);

    constructor(string memory _electionName) {
        owner = msg.sender;
        electionName = _electionName;
    }

    // Setup of the election
    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function addCandidates(string[] memory _names) public onlyOwner {
        require (!electionActive, "Election has already started");
        for (uint256 i = 0; i < _names.length; i++) {
            candidates.push(Candidate(_names[i], 0));
        }
    }

    // Start the election
    function startElection(uint256 _electionDuration) public onlyOwner {
        require(!electionActive);
        require(merkleRoot != 0, "Merkle root is not set");
        require(candidates.length > 0, "No candidates added");
        electionActive = true;
        electionStart = block.timestamp;
        electionDuration = _electionDuration;
        electionEnd = electionStart + _electionDuration;
    }

    // Voting
    function vote(bytes32[] memory _merkleProof, bytes memory _encryptedVote) public {
        require(electionActive, "Election is not active");
        require(electionEnd <= block.timestamp, "Election is over");
        require(!voters[msg.sender].voted, "You have already voted");
        bytes32 merkleLeaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRoot, merkleLeaf), "You are not eligible to vote");
        
        voters[msg.sender].voted = true;
        voters[msg.sender].encryptedVote = _encryptedVote;

        emit VoteSubmitted(msg.sender, _encryptedVote);
    }

    // End Election
    function endElection() public {
        require(block.timestamp >= electionEnd, "Election is still ongoing");
        require(electionActive, "Election has not started");
        electionActive = false;
        electionStart = 0;
        electionDuration = 0;
        electionEnd = 0;
    }

    // Helper Functions & Modifiers
    function getNumCandidates() public view returns (uint256) {
        return candidates.length;
    }

    function getCandidate(uint256 index) public view returns (string memory) {
        require(index < candidates.length, "Invalid candidate index");
        Candidate memory candidate = candidates[index];
        return (candidate.name);
    }

    function getCandidates() public view returns (Candidate[] memory) {
        return candidates;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
}
