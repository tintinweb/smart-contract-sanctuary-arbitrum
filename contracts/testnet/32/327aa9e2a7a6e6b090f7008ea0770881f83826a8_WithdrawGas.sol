/**
 *Submitted for verification at Arbiscan on 2022-12-14
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;
pragma abicoder v2;

contract WithdrawGas {
    string constant NATIVE_TOKEN = "ETH";
    uint256 constant NOT_ENTERED = 1;
    uint256 constant ENTERED = uint256(int256(-1));

    address public _SIGNER_ = 0x046d3CB5C07382c5dB548e62F5786D19Ad3a0536;
    mapping(address => uint256) internal _WD_ID_;
    uint256 private _STATUS_;

    event LogWithdraw(
        address indexed account,
        string token_symbol,
        uint256 amount,
        uint256 withdrawid
    );

    modifier nonReentrant() {
        require(_STATUS_ != ENTERED, "ReentrancyGuard: reentrant call");
        _STATUS_ = ENTERED;
        _;
        _STATUS_ = NOT_ENTERED;
    }

    function withdraw(
        address payable account,
        string calldata token_symbol,
        uint256 amount,
        uint256 withdrawid,
        uint256 timestamp,
        bytes32 r,
        bytes32 s,
        uint8 v
    )
        external
        nonReentrant
    {
        require(
            msg.sender == account,
            "Aboard: withdraw msg sender is not account"
        );

        //check timestamp
        require(
            block.timestamp < timestamp,
            "Aboard: withdraw timestamp expired"
        );

        //check signature
        bytes32 applyhash = _getApplyHash(account, token_symbol, amount, withdrawid, timestamp);
        require(
            _SIGNER_ == ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", applyhash)), v, r, s),
            "Aboard: withdraw invalid signature"
        );

        //check withdrawid
        require(
            _WD_ID_[account] < withdrawid,
            "Aboard: withdraw id fail"
        );
        _WD_ID_[account] = withdrawid;
        
        //check token status
        // P1Types.TokenInfo storage token_info = _TOKEN_MAP_[token_symbol];
        // require(
        //     token_info.status != 0,
        //     "Aboard: withdraw token incorrect status"
        // );

        //native or erc20
        if (keccak256(abi.encodePacked(token_symbol)) == keccak256(abi.encodePacked(NATIVE_TOKEN))) {
            account.transfer(amount);
        }
        
        //bytes32 magin_funding = toBytes32_signed(funding);
        emit LogWithdraw(
            account,
            token_symbol,
            amount,
            withdrawid
        );
    }

    /**
     * @dev Returns the hash of an withdraw apply.
     */
    function _getApplyHash(
        address account,
        string calldata token_symbol,
        uint256 amount,
        uint256 withdrawid,
        uint256 timestamp
    )
        private
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(account, token_symbol, amount, withdrawid, timestamp));
    }

    receive() external payable {}
}