//SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.4.21 <0.8.0;


//TO DO: CHECK if events are not necessary in a voting action

contract VoteManager {
	address public constant VOTE_SENTINEL = address(0x43);

	mapping (uint256 => mapping (address => address)) internal votes;

	function voteExists(uint256 _vote)
		internal
		view
		returns (bool)
	{
		return votes[_vote][VOTE_SENTINEL] != address(0x0);
	}

	modifier voteExistsM(uint256 _vote)
	{
		require(voteExists(_vote), "No vote");
		_;
	}

	function createVote(uint256 _vote)
		internal
	{
		require(votes[_vote][VOTE_SENTINEL] == address(0x0), "Vote exists");
		votes[_vote][VOTE_SENTINEL] = VOTE_SENTINEL;
	}

	function hasVoted(uint256 _vote, address _voter)
		internal
		view
		voteExistsM(_vote)
		returns (bool)
	{
		return votes[_vote][_voter] != address(0x0);
	}

	function castVote(uint256 _vote, address _voter)
		internal
		voteExistsM(_vote)
	{
		require(_voter != VOTE_SENTINEL, "Invalid voter");
		require(!hasVoted(_vote, _voter), "Already voted");

		votes[_vote][_voter] = votes[_vote][VOTE_SENTINEL];
		votes[_vote][VOTE_SENTINEL] = _voter;
	}

	function removeVote(uint256 _vote, address _voter)
		internal
		voteExistsM(_vote)
	{
		require(_voter != VOTE_SENTINEL, "Invalid voter");
		require(hasVoted(_vote, _voter), "Not voted");

	/* Search for curr such that the next elemt is _key */
		address curr = VOTE_SENTINEL;
		while (curr != address(0x0) && votes[_vote][curr] != _voter){
			curr = votes[_vote][curr];
		}
		require(votes[_vote][curr] == _voter, "Key not found");

		votes[_vote][curr] = votes[_vote][_voter];
		delete votes[_vote][_voter];
	}

	function countVotes(uint256 _vote)
		internal
		view
		voteExistsM(_vote)
		returns (uint)
	{
		uint ret = 0;
		for (address curr = votes[_vote][VOTE_SENTINEL]; curr != VOTE_SENTINEL;
		     curr = votes[_vote][curr]) {
		     ret++;
		}

		return ret;
	}

	function getVoters(uint256 _vote)
		public
		view
		voteExistsM(_vote)
		returns (address[] memory)
	{
		address[] memory ret = new address[](countVotes(_vote));

		uint idx = 0;
		for (address curr = votes[_vote][VOTE_SENTINEL]; curr != VOTE_SENTINEL;
			 curr = votes[_vote][curr]) {
			ret[idx++] = curr;
		}

		return ret;
	}

	function endVote(uint256 _vote)
		internal
		voteExistsM(_vote)
	{
		require(votes[_vote][VOTE_SENTINEL] != address(0x0), "No vote");

		address next;
		for (address curr = votes[_vote][VOTE_SENTINEL]; curr != VOTE_SENTINEL; curr = next) {
			next = votes[_vote][curr];
			delete votes[_vote][curr];
		}

		delete votes[_vote][VOTE_SENTINEL];
	}
}
