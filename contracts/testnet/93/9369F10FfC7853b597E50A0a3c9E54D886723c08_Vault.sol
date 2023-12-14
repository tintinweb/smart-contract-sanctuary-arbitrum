// SPDX-License-Identifier: MIT
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    /**
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

pragma solidity ^0.8.0;

contract Vault {
    address private owner;
    address public router;
    address private constant USDC = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyRouter() {
        require(msg.sender == router);
        _;
    }

    mapping(address => uint) public requestIdx;
    mapping(bytes32 => Request) public requests;
    bytes32[] public arrayOfRequests;

    mapping(address => bool) public publishInfo;

    struct Request {
        uint256 id;
        address lender;
        address borrower;
        uint256 amount;
        uint256 interest;
        uint256 duration;
        bool isFinalised;
        uint256 genesisTime;
        uint256 emi;
        bool defaulted;
        uint256 amountRepaid;
    }

    function setRouter(address _router) public onlyOwner {
        router = _router;
    }

    function createRequest(
        address _lender,
        uint256 _amount,
        uint256 _interest,
        uint256 _duration
    ) external onlyRouter {
        Request memory request = Request(
            requestIdx[_lender],
            _lender,
            address(0),
            _amount,
            _interest,
            _duration,
            false,
            0,
            0,
            false,
            0
        );
        bytes32 requestKey = getRequestKey(_lender, requestIdx[_lender]);
        requestIdx[_lender]++;
        requests[requestKey] = request;
        arrayOfRequests.push(requestKey);
    }

    function getAllRequests()
        external
        view
        onlyRouter
        returns (Request[] memory)
    {
        Request[] memory _requests = new Request[](arrayOfRequests.length);
        uint256 validRequestsCount = 0;

        for (uint256 i = 0; i < arrayOfRequests.length; i++) {
            Request memory request = requests[arrayOfRequests[i]];
            if (request.borrower == address(0)) {
                _requests[validRequestsCount] = request;
                validRequestsCount++;
            }
        }

        // Resize the array to remove unused slots
        assembly {
            mstore(_requests, validRequestsCount)
        }
        return _requests;
    }

    function getNotNullLenderRequests(
        address _lender
    ) external view onlyRouter returns (Request[] memory) {
        Request[] memory _requests = new Request[](requestIdx[_lender]);
        uint256 validRequestsCount = 0;

        for (uint256 i = 0; i < requestIdx[_lender]; i++) {
            Request memory request = requests[getRequestKey(_lender, i)];
            if (request.borrower != address(0)) {
                _requests[validRequestsCount] = request;
                validRequestsCount++;
            }
        }

        assembly {
            mstore(_requests, validRequestsCount)
        }
        return _requests;
    }

    function removeBorrowerFromRequest(
        address _lender,
        uint256 id
    ) external onlyRouter {
        requests[getRequestKey(_lender, id)].borrower = address(0);
    }

    function addBorrowerToRequest(
        address _lender,
        uint256 id,
        address _borrower
    ) external onlyRouter {
        requests[getRequestKey(_lender, id)].borrower = _borrower;
    }

    function convertRequestToOffer(
        address _lender,
        uint256 id
    ) external onlyRouter {
        if (
            IERC20(USDC).balanceOf(_lender) <
            requests[getRequestKey(_lender, id)].amount
        ) {
            revert("Insufficient balance with lender for  USDC.");
        }

        if (
            IERC20(USDC).allowance(msg.sender, address(this)) <
            requests[getRequestKey(_lender, id)].amount
        ) {
            IERC20(USDC).approve(
                msg.sender,
                requests[getRequestKey(_lender, id)].amount
            );
        }

        IERC20(USDC).transferFrom(
            msg.sender,
            requests[getRequestKey(_lender, id)].borrower,
            requests[getRequestKey(_lender, id)].amount
        );

        requests[getRequestKey(_lender, id)].isFinalised = true;
        requests[getRequestKey(_lender, id)].genesisTime = block.timestamp;
    }

    function payDues(address _lender, uint256 id) external onlyRouter {
        Request memory request = requests[getRequestKey(_lender, id)];

        if (
            IERC20(USDC).balanceOf(request.borrower) <
            request.amount * (1 + request.interest / 100)
        ) {
            revert("Insufficient balance with borrower for USDC.");
        }

        if (
            IERC20(USDC).allowance(msg.sender, address(this)) <
            request.amount * (1 + request.interest / 100)
        ) {
            IERC20(USDC).approve(
                request.borrower,
                request.amount * (1 + request.interest / 100)
            );
        }

        IERC20(USDC).transferFrom(
            request.borrower,
            request.lender,
            request.amount * (1 + request.interest / 100)
        );

        requests[getRequestKey(_lender, id)].amountRepaid +=
            requests[getRequestKey(_lender, id)].amount *
            (1 + request.interest / 100);
    }

    function checkForDefaulters(
        address _lender
    ) external onlyRouter returns (Request[] memory) {
        Request[] memory _requests = new Request[](requestIdx[_lender]);
        uint256 validRequestsCount = 0;

        for (uint id = 0; id < requestIdx[_lender]; id++) {
            if (
                (block.timestamp >
                    requests[getRequestKey(_lender, id)].genesisTime +
                        requests[getRequestKey(_lender, id)].duration) &&
                (requests[getRequestKey(_lender, id)].amountRepaid <
                    requests[getRequestKey(_lender, id)].amount *
                        (1 +
                            requests[getRequestKey(_lender, id)].interest /
                            100))
            ) {
                requests[getRequestKey(_lender, id)].defaulted = true;
                publishInfo[
                    requests[getRequestKey(_lender, id)].borrower
                ] = true;
                _requests[validRequestsCount] = requests[
                    getRequestKey(_lender, id)
                ];
            }
        }

        assembly {
            mstore(_requests, validRequestsCount)
        }

        return _requests;
    }

    function getAllDefaulterAddress() external view returns (address[] memory) {
        address[] memory _addresses = new address[](arrayOfRequests.length);
        uint256 validAddressesCount = 0;

        for (uint256 i = 0; i < arrayOfRequests.length; i++) {
            if (publishInfo[requests[arrayOfRequests[i]].borrower]) {
                _addresses[validAddressesCount] = requests[arrayOfRequests[i]]
                    .borrower;
                validAddressesCount++;
            }
        }

        assembly {
            mstore(_addresses, validAddressesCount)
        }
        return _addresses;
    }

    function getBorrowerRequest(
        address _borrow
    ) external view onlyRouter returns (Request[] memory) {
        Request[] memory _requests = new Request[](arrayOfRequests.length);
        uint256 validRequestsCount = 0;

        for (uint256 i = 0; i < arrayOfRequests.length; i++) {
            Request memory request = requests[arrayOfRequests[i]];
            if (request.borrower == _borrow) {
                _requests[validRequestsCount] = request;
                validRequestsCount++;
            }
        }

        // Resize the array to remove unused slots
        assembly {
            mstore(_requests, validRequestsCount)
        }
        return _requests;
    }

    function getRequestKey(
        address account,
        uint256 index
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(account, index));
    }
}