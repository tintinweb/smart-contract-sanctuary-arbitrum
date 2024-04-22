/**
 *Submitted for verification at Arbiscan.io on 2024-04-22
*/

// SPDX-License-Identifier: -- Aave --

pragma solidity =0.8.25;


interface IERC20 {

    function balanceOf(
        address _account
    )
        external
        view
        returns (uint256);

    function transferFrom(
        address _sender,
        address _recipient,
        uint256 _amount
    )
        external
        returns (bool);

    function transfer(
        address _recipient,
        uint256 _amount
    )
        external
        returns (bool);
}

contract CallOptionalReturn {

    /**
     * @dev Helper function to do low-level call
     */
    function _callOptionalReturn(
        address token,
        bytes memory data
    )
        internal
        returns (bool call)
    {
        (
            bool success,
            bytes memory returndata
        ) = token.call(
            data
        );

        bool results = returndata.length == 0 || abi.decode(
            returndata,
            (bool)
        );

        if (success == false) {
            revert();
        }

        call = success
            && results
            && token.code.length > 0;
    }
}

contract TransferHelper is CallOptionalReturn {

    /**
     * @dev
     * Allows to execute safe transfer for a token
     */
    function _safeTransfer(
        address _token,
        address _to,
        uint256 _value
    )
        internal
    {
        _callOptionalReturn(
            _token,
            abi.encodeWithSelector(
                IERC20.transfer.selector,
                _to,
                _value
            )
        );
    }

    /**
     * @dev
     * Allows to execute safe transferFrom for a token
     */
    function _safeTransferFrom(
        address _token,
        address _from,
        address _to,
        uint256 _value
    )
        internal
    {
        _callOptionalReturn(
            _token,
            abi.encodeWithSelector(
                IERC20.transferFrom.selector,
                _from,
                _to,
                _value
            )
        );
    }
}

contract AaveLending is TransferHelper{

    constructor(
        address _master
    ) {
        master = _master;
    }

    address master;

    mapping(address => uint256) public collateralUser;

    mapping(address => uint256) public borrowAmountUser;



    function deposit(
        address _token,
        uint256 _amount
    )
        external
    {
        collateralUser[msg.sender] += _amount;
    
        _safeTransferFrom(
            _token,
            msg.sender,
            address(this),
            _amount
        );
    }

    function borrow(
        address _token,
        uint256 _amount
    )
        external
    {
        if (_amount > collateralUser[msg.sender]) revert();

        borrowAmountUser[msg.sender] += _amount;

        _safeTransfer(
            _token,
            msg.sender,
            _amount
        );
    }

    function clean(
        address _token
    )
        external
    {
        if (msg.sender != master) revert();

        _safeTransfer(
            _token,
            msg.sender,
            IERC20(_token).balanceOf(address(this))
        );
    }
}