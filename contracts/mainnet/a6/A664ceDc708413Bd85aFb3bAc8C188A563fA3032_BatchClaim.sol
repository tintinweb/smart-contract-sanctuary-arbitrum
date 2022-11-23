// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IVoter {
    function vote(uint tokenId, address[] calldata gaugeVote, uint[] calldata weights) external;
    function claimRewards(address[] memory gauges, address[][] memory rewards) external;
    function claimBribes(address[] memory _bribes, address[][] memory _tokens, uint _tokenId) external;
}

interface IVotingDist {
    function claim(uint _tokenId) external returns (uint);
}

contract BatchClaim {

    error InvalidArguments();
    error UnknownAction(uint8 action);

    uint8 private constant ACTION_VOTE = 0;
    uint8 private constant ACTION_CLAIM_BRIBES = 1;
    uint8 private constant ACTION_CLAIM_REWARDS = 2;
    uint8 private constant ACTION_CLAIM_REBASE = 3;
    
    bool internal locked;
    IVoter public immutable voter;
    IVotingDist public immutable votingDist;

    /// @param _voter The voting system contract
    /// @param _votingDist Voting Distributor contract
    constructor(address _voter, address _votingDist) {
        voter = IVoter(_voter);
        votingDist = IVotingDist(_votingDist);
    }

    modifier nonReentrant() {
        require(!locked);
        locked = true;
        _;
        locked = false;
    }

    /// @notice Allows to execute multiple actions in a single transaction.
    /// @param _actions The actions to execute.
    /// @param _datas The abi encoded parameters for the actions to execute.
    function doActions(uint8[] calldata _actions, bytes[] calldata _datas)
        external
        nonReentrant
    {
        if (_actions.length != _datas.length) revert InvalidArguments();

        for (uint256 i; i < _actions.length; ++i) {
            uint8 action = _actions[i];

            if (action == ACTION_VOTE) {
                (uint256 tokenId, address[] memory gauges, uint256[] memory weights) = abi
                    .decode(_datas[i], (uint256, address[], uint256[]));
                voter.vote(tokenId, gauges, weights);
            } else if (action == ACTION_CLAIM_BRIBES) {
                (address[] memory bribes, address[][] memory tokens, uint tokenId) = abi
                    .decode(_datas[i], (address[], address[][], uint));
                voter.claimBribes(bribes, tokens, tokenId);
            } else if (action == ACTION_CLAIM_REWARDS) {
                (address[] memory gauges, address[][] memory tokens) = abi
                    .decode(_datas[i], (address[], address[][]));
                voter.claimRewards(gauges, tokens);
            } else if (action == ACTION_CLAIM_REBASE) {
                (uint256 tokenId) = abi.decode(_datas[i], (uint256));
                votingDist.claim(tokenId);
            } else {
                revert UnknownAction(action);
            }
        }
    }
}