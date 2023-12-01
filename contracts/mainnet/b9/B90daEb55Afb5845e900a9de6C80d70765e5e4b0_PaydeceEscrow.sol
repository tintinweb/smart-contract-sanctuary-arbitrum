// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./IERC20.sol";
import "./Address.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./Context.sol";
import "./Ownable.sol";

contract PaydeceEscrow is ReentrancyGuard, Ownable {
    // 0.1 is 100 because it is multiplied by a thousand => 0.1 X 1000 = 100
    uint16 public feeTaker;
    uint16 public feeMaker;
    uint256 public feesAvailableNativeCoin;
    uint256 public timeProcess; //Time they have to complete the transaction

    using SafeERC20 for IERC20;
    mapping(uint => Escrow) public escrows;
    mapping(address => bool) private whitelistedStablesAddresses;
    mapping(IERC20 => uint) public feesAvailable;

    enum EscrowStatus {
        Unknown, //0
        ACTIVE, // 1,
        CRYPTOS_IN_CUSTODY, // 2,
        FIATCOIN_TRANSFERED, // 3,
        COMPLETED, // 4,
        REFUND, // 7,
        CANCEL_MAKER, //9
        CANCEL_TAKER //10
    }

    struct Escrow {
        address payable maker; //Maker
        address payable taker; //Taker
        bool maker_premium;
        bool taker_premium;
        uint256 value; // Purchase amount
        uint16 takerfee; //Fee Taker
        uint16 makerfee; //Fee Maker
        IERC20 currency; //Money
        EscrowStatus status; //Status
        uint256 created;
    }

    event EscrowDeposit(uint indexed orderId, Escrow escrow);
    event EscrowComplete(uint indexed orderId, Escrow escrow);
    event EscrowCancelMaker(uint indexed orderId, Escrow escrow);
    event EscrowCancelTaker(uint indexed orderId, Escrow escrow);
    event EscrowMarkAsPaid(uint indexed orderId, Escrow escrow);
    event EscrowMarkAsPaidOwner(uint indexed orderId, Escrow escrow);
    event EscrowRefundMaker(uint indexed orderId, Escrow escrow);
    event EscrowRefundMakerNativeCoin(uint indexed orderId, Escrow escrow);
    event setFeeMakerEvent(uint16 feeMaker);
    event setFeeTakerEvent(uint16 feeMaker);
    event setTimeProcessEvent(uint256 timeProcess);
    event addStablesAddressesEvent(address addressStable);
    event delStablesAddressesEvent(address addressStable);

    /**
     * @notice  modifier only the maker
     * @param   _orderId  .
     */
    modifier onlyMaker(uint _orderId) {
        require(
            msg.sender == escrows[_orderId].maker,
            "Only Maker can call this"
        );
        _;
    }

    /**
     * @notice  modifier only the taker
     * @param   _orderId  .
     */
    modifier onlyTaker(uint _orderId) {
        require(
            msg.sender == escrows[_orderId].taker,
            "Only Taker can call this"
        );
        _;
    }

    constructor() {
        timeProcess = 45 * 60; //45mi
    }

    // ================== Begin External functions ==================
    /**
     * @notice  Set Fee Taker
     * @param   _feeTaker  .
     */
    function setFeeTaker(uint16 _feeTaker) external onlyOwner {
        require(
            _feeTaker >= 0 && _feeTaker <= (1 * 1000),
            "The fee can be from 0% to 1%"
        );
        feeTaker = _feeTaker;

        emit setFeeTakerEvent(_feeTaker);
    }

    /**
     * @notice  Set Fee Maker
     * @param   _feeMaker  .
     */
    function setFeeMaker(uint16 _feeMaker) external onlyOwner {
        require(
            _feeMaker >= 0 && _feeMaker <= (1 * 1000),
            "The fee can be from 0% to 1%"
        );
        feeMaker = _feeMaker;

        emit setFeeMakerEvent(_feeMaker);
    }

    /**
     * @notice  Set Time Process
     * @param   _timeProcess  .
     */
    function setTimeProcess(uint256 _timeProcess) external onlyOwner {
        require(_timeProcess > 0, "The timeProcess can be 0");
        timeProcess = _timeProcess;

        emit setTimeProcessEvent(timeProcess);
    }

    /**
     * @notice  Create Escrow
     * @param   _orderId  .
     * @param   _taker  .
     * @param   _value  .
     * @param   _currency  .
     * @param   _maker_premium  .
     * @param   _taker_premium  .
     */
    function createEscrow(
        uint _orderId,
        address payable _taker,
        uint256 _value,
        IERC20 _currency,
        bool _maker_premium,
        bool _taker_premium
    ) external virtual {
        require(_taker != address(0), "The address taker cannot be empty");

        require(
            escrows[_orderId].status == EscrowStatus.Unknown,
            "Escrow already exists"
        );

        require(
            whitelistedStablesAddresses[address(_currency)],
            "Address Stable to be whitelisted"
        );

        require(msg.sender != _taker, "Taker cannot be the same as maker");

        require(_value > 0, "The parameter value cannot be zero");

        uint8 _decimals = _currency.decimals();

        //Gets the amount to transfer from the buyer to the contract
        uint256 _amountFeeMaker = 0;
        
        if (!_maker_premium) {
            _amountFeeMaker = ((_value * (feeMaker * 10 ** _decimals)) /
                (100 * 10 ** _decimals)) / 1000;

            // Add fee
            feesAvailable[_currency] += _amountFeeMaker;    
        }        

        //Transfer USDT to contract
        _currency.safeTransferFrom(
            msg.sender,
            address(this),
            (_value + _amountFeeMaker)
        );

        escrows[_orderId] = Escrow(
            payable(msg.sender),
            _taker,
            _maker_premium,
            _taker_premium,
            _value,
            feeTaker,
            feeMaker,
            _currency,
            EscrowStatus.CRYPTOS_IN_CUSTODY,
            block.timestamp
        );

        emit EscrowDeposit(_orderId, escrows[_orderId]);
    }

    /**
     * @notice  Create Escrow Native Coin
     * @param   _orderId  .
     * @param   _taker  .
     * @param   _value  .
     * @param   _maker_premium  .
     * @param   _taker_premium  .
     */
    function createEscrowNativeCoin(
        uint _orderId,
        address payable _taker,
        uint256 _value,
        bool _maker_premium,
        bool _taker_premium
    ) external payable virtual {
        require(
            escrows[_orderId].status == EscrowStatus.Unknown,
            "Escrow already exists"
        );
        require(_taker != address(0), "The address taker cannot be empty");

        require(msg.sender != _taker, "Taker cannot be the same as maker");

        require(_value > 0, "The parameter value cannot be zero");

        uint8 _decimals = 18;

        //Gets the amount to transfer from the buyer to the contract
        uint256 _amountFeeMaker = 0;

        if (!_maker_premium) {
            _amountFeeMaker = ((_value * (feeMaker * 10 ** _decimals)) /
                (100 * 10 ** _decimals)) / 1000;

            //Add fee
            feesAvailableNativeCoin += _amountFeeMaker;    
        }

        //Verification was added for the user to send the exact amount of native tokens to escrow.
        require((_value + _amountFeeMaker) == msg.value, "Incorrect amount");

        escrows[_orderId] = Escrow(
            payable(msg.sender),
            _taker,
            _maker_premium,
            _taker_premium,
            _value,
            feeTaker,
            feeMaker,
            IERC20(address(0)),
            EscrowStatus.CRYPTOS_IN_CUSTODY,
            block.timestamp
        );

        emit EscrowDeposit(_orderId, escrows[_orderId]);
    }

    /**
     * @notice  Release Escrow Owner
     * @param   _orderId  .
     */
    function releaseEscrowOwner(uint _orderId) external onlyOwner {
        _releaseEscrow(_orderId);
    }

    /**
     * @notice  Release Escrow Owner Native Coin
     * @param   _orderId  .
     */
    function releaseEscrowOwnerNativeCoin(uint _orderId) external onlyOwner {
        _releaseEscrowNativeCoin(_orderId);
    }

    /**
     * @notice  Release Escrow
     * @param   _orderId  .
     */
    function releaseEscrow(uint _orderId) external onlyMaker(_orderId) {
        _releaseEscrow(_orderId);
    }

    /**
     * @notice  Release Escrow Native Coin
     * @param   _orderId  .
     */
    function releaseEscrowNativeCoin(
        uint _orderId
    ) external onlyMaker(_orderId) {
        _releaseEscrowNativeCoin(_orderId);
    }

    /**
     * @notice  release funds to the maker - cancelled contract
     * @param   _orderId  .
     */
    function refundMaker(uint _orderId) external nonReentrant onlyOwner {
        require( 
            escrows[_orderId].status == EscrowStatus.CRYPTOS_IN_CUSTODY || 
            escrows[_orderId].status == EscrowStatus.FIATCOIN_TRANSFERED,
            "Refund not approved"
        );

        uint256 _value = escrows[_orderId].value;
        address _maker = escrows[_orderId].maker;
        IERC20 _currency = escrows[_orderId].currency;

        uint256 _amountFeeMaker = getAmountFeeMaker(_orderId, false);

        // write as refun, in case transfer fails
        escrows[_orderId].status = EscrowStatus.REFUND;

        //update fee
        feesAvailable[escrows[_orderId].currency] -= _amountFeeMaker;

        _currency.safeTransfer(_maker, _value + _amountFeeMaker);

        emit EscrowRefundMaker(_orderId, escrows[_orderId]);
    }

    /**
     * @notice  Refund Maker Native Coin
     * @param   _orderId  .
     */
    function refundMakerNativeCoin(
        uint _orderId
    ) external nonReentrant onlyOwner {
        require(
            escrows[_orderId].status == EscrowStatus.CRYPTOS_IN_CUSTODY || 
            escrows[_orderId].status == EscrowStatus.FIATCOIN_TRANSFERED,
            "Refund not approved"
        );

        uint256 _value = escrows[_orderId].value;
        address _maker = escrows[_orderId].maker;

        uint256 _amountFeeMaker = getAmountFeeMaker(_orderId, true);

        // write as refun, in case transfer fails
        escrows[_orderId].status = EscrowStatus.REFUND;

        feesAvailableNativeCoin -= _amountFeeMaker;

        //Transfer call
        (bool sent, ) = payable(address(_maker)).call{
            value: _value + _amountFeeMaker
        }("");
        require(sent, "Transfer failed.");

        emit EscrowRefundMakerNativeCoin(_orderId, escrows[_orderId]);
    }

    /**
     * @notice  Withdraw Fees
     * @param   _currency  .
     */
    function withdrawFees(IERC20 _currency) external onlyOwner {
        uint _amount;

        // This check also prevents underflow
        require(feesAvailable[_currency] > 0, "Amount > feesAvailable");

        _amount = feesAvailable[_currency];

        feesAvailable[_currency] -= _amount;

        _currency.safeTransfer(owner(), _amount);
    }

    /**
     * @notice  Withdraw Fees Native Coin
     */
    function withdrawFeesNativeCoin() external onlyOwner {
        uint256 _amount;

        // This check also prevents underflow
        require(feesAvailableNativeCoin > 0, "Amount > feesAvailable");

        _amount = feesAvailableNativeCoin;

        feesAvailableNativeCoin -= _amount;

        //Transfer
        (bool sent, ) = payable(msg.sender).call{value: _amount}("");
        require(sent, "Transfer failed.");
    }

    /**
     * @notice  Get State
     * @param   _orderId  .
     * @return  EscrowStatus  .
     */
    function getState(uint _orderId) external view returns (EscrowStatus) {
        Escrow memory _escrow = escrows[_orderId];
        return _escrow.status;
    }

    /**
     * @notice  Add Stables Addresses
     * @param   _addressStableToWhitelist  .
     */
    function addStablesAddresses(
        address _addressStableToWhitelist
    ) external onlyOwner {
        whitelistedStablesAddresses[_addressStableToWhitelist] = true;

        emit addStablesAddressesEvent(_addressStableToWhitelist);
    }

    /**
     * @notice  Delete Stables Addresses
     * @param   _addressStableToWhitelist  .
     */
    function delStablesAddresses(
        address _addressStableToWhitelist
    ) external onlyOwner {
        whitelistedStablesAddresses[_addressStableToWhitelist] = false;

        emit delStablesAddressesEvent(_addressStableToWhitelist);
    }

    /**
     * @notice  Cancel Maker
     * @param   _orderId  .
     */
    function cancelMaker(
        uint256 _orderId
    ) external nonReentrant onlyMaker(_orderId) {
        // Validate the Escrow status
        require(
            escrows[_orderId].status == EscrowStatus.CRYPTOS_IN_CUSTODY,
            "Status must be CRYPTOS_IN_CUSTODY"
        );

        uint256 _timeDiff = block.timestamp - escrows[_orderId].created;

        // Process time validation
        require(_timeDiff > timeProcess, "Time is still running out.");

        // Status change
        escrows[_orderId].status = EscrowStatus.CANCEL_MAKER;

        //get Amount Fee Maker
        uint256 _amountFeeMaker = getAmountFeeMaker(_orderId, false);

        //update frees
        feesAvailable[escrows[_orderId].currency] -= _amountFeeMaker;

        //Transfer to maker
        escrows[_orderId].currency.safeTransfer(
            escrows[_orderId].maker,
            escrows[_orderId].value + _amountFeeMaker
        );

        // emit event
        emit EscrowCancelMaker(_orderId, escrows[_orderId]);
    }

    /**
     * @notice  Cancel Maker Native
     * @param   _orderId  .
     */
    function cancelMakerNative(
        uint256 _orderId
    ) external nonReentrant onlyMaker(_orderId) {
        // Validate the Escrow status
        require(
            escrows[_orderId].status == EscrowStatus.CRYPTOS_IN_CUSTODY,
            "Status must be CRYPTOS_IN_CUSTODY"
        );

        uint256 _timeDiff = block.timestamp - escrows[_orderId].created;

        // Process time validation
        require(_timeDiff > timeProcess, "Time is still running out.");

        // Status change
        escrows[_orderId].status = EscrowStatus.CANCEL_MAKER;

        //get Amount Fee Maker
        uint256 _amountFeeMaker = getAmountFeeMaker(_orderId, true);

        //update fee
        feesAvailableNativeCoin -= _amountFeeMaker; 

        //Transfer call
        (bool sent, ) = payable(address(escrows[_orderId].maker)).call{
            value: (escrows[_orderId].value + _amountFeeMaker)
        }("");
        require(sent, "Transfer failed.");

        // emit event
        emit EscrowCancelMaker(_orderId, escrows[_orderId]);
    }

    /**
     * @notice  Cancel Taker
     * @param   _orderId  .
     */
    function cancelTaker(
        uint256 _orderId
    ) external nonReentrant onlyTaker(_orderId) {
        // Validate the Escrow status
        require(
            escrows[_orderId].status == EscrowStatus.CRYPTOS_IN_CUSTODY,
            "Status must be CRYPTOS_IN_CUSTODY"
        );

        // Status change
        escrows[_orderId].status = EscrowStatus.CANCEL_TAKER;

        //get amountFeeMaker
        uint256 _amountFeeMaker = getAmountFeeMaker(_orderId,false);

        //update fee amount
        feesAvailable[escrows[_orderId].currency] -= _amountFeeMaker;

        //Transfer to Taker
        escrows[_orderId].currency.safeTransfer(
            escrows[_orderId].maker,
            (escrows[_orderId].value + _amountFeeMaker)
        );

        // emit event
        emit EscrowCancelTaker(_orderId, escrows[_orderId]);
    }

    /**
     * @notice  Cancel Taker Native
     * @param   _orderId  .
     */
    function cancelTakerNative(
        uint256 _orderId
    ) external nonReentrant onlyTaker(_orderId) {
        // Validate the Escrow status
        require(
            escrows[_orderId].status == EscrowStatus.CRYPTOS_IN_CUSTODY,
            "Status must be CRYPTOS_IN_CUSTODY"
        );

        // Status change
        escrows[_orderId].status = EscrowStatus.CANCEL_TAKER;

        //get amountFeeTaker
        uint256 _amountFeeMaker = getAmountFeeMaker(_orderId, true);

        //update fee amount
        feesAvailableNativeCoin -= _amountFeeMaker;

        (bool sent, ) = escrows[_orderId].maker.call{
            value: escrows[_orderId].value + _amountFeeMaker
        }("");
        require(sent, "Transfer failed.");

        // emit event
        emit EscrowCancelTaker(_orderId, escrows[_orderId]);
    }

    /**
     * @notice  Set Mark As Paid
     * @param   _orderId  .
     */
    function setMarkAsPaid(uint256 _orderId) external onlyTaker(_orderId) {
        // Validate the Escrow status
        require(
            escrows[_orderId].status == EscrowStatus.CRYPTOS_IN_CUSTODY,
            "Status must be CRYPTOS_IN_CUSTODY"
        );

        escrows[_orderId].status = EscrowStatus.FIATCOIN_TRANSFERED;

        // emit event
        emit EscrowMarkAsPaid(_orderId, escrows[_orderId]);
    }

    /**
     * @notice  Set Mark As Paid Owner
     * @param   _orderId  .
     */
    function setMarkAsPaidOwner(uint256 _orderId) external onlyOwner {
        // Validate the Escrow status
        require(
            escrows[_orderId].status == EscrowStatus.CRYPTOS_IN_CUSTODY,
            "Status must be CRYPTOS_IN_CUSTODY"
        );

        escrows[_orderId].status = EscrowStatus.FIATCOIN_TRANSFERED;

        // emit event
        emit EscrowMarkAsPaidOwner(_orderId, escrows[_orderId]);
    }

    // ================== End External functions ==================

    // ================== Begin External functions that are pure ==================
    /**
     * @notice  Get Version
     * @return  string  .
     */
    function version() external pure virtual returns (string memory) {
        return "4.2.0";
    }

    // ================== End External functions that are pure ==================

    /// ================== Begin Public functions ==================

    /// ================== End Public functions ==================

    // ================== Begin Private functions ==================
    /**
     * @notice  Release Escrow
     * @param   _orderId  .
     */
    function _releaseEscrow(uint _orderId) private nonReentrant {
        require(
            escrows[_orderId].status == EscrowStatus.FIATCOIN_TRANSFERED,
            "Status must be FIATCOIN_TRANSFERED"
        );

        //Gets the amount to transfer from the buyer to the contract
        uint256 _amountFeeTaker = getAmountFeeTaker(_orderId, false);

        feesAvailable[escrows[_orderId].currency] += _amountFeeTaker;

        // write as complete, in case transfer fails
        escrows[_orderId].status = EscrowStatus.COMPLETED;

        //Transfer to taker Price Asset - FeeTaker
        escrows[_orderId].currency.safeTransfer(
            escrows[_orderId].taker,
            escrows[_orderId].value - _amountFeeTaker
        );

        emit EscrowComplete(_orderId, escrows[_orderId]);
    }

    /**
     * @notice  Release Escrow Native Coin
     * @param   _orderId  .
     */
    function _releaseEscrowNativeCoin(uint _orderId) private nonReentrant {
        require(
            escrows[_orderId].status == EscrowStatus.FIATCOIN_TRANSFERED,
            "Native Coin has not been deposited"
        );

        //Gets the amount to transfer from the buyer to the contract
        uint256 _amountFeeTaker = 0;
        if (!escrows[_orderId].taker_premium) {
            _amountFeeTaker = getAmountFeeTaker(_orderId, true);    
        }

        //Record the fees obtained for Paydece
        feesAvailableNativeCoin += _amountFeeTaker;

        // write as complete, in case transfer fails
        escrows[_orderId].status = EscrowStatus.COMPLETED;

        //Transfer to taker Price Asset - FeeTaker
        (bool sent, ) = escrows[_orderId].taker.call{
            value: escrows[_orderId].value - _amountFeeTaker
        }("");
        require(sent, "Transfer failed.");

        emit EscrowComplete(_orderId, escrows[_orderId]);
    }

    /**
     * @notice  Get Amount Fee Taker
     * @param   _orderId  .
     * @return  uint256  .
     */
    function getAmountFeeTaker(
        uint256 _orderId,
        bool _native
    ) private view returns (uint256) {
        //get decimal of stable
        uint8 _decimals = 18;
        uint256 _amountFeeTaker = 0;

        if (_native == false) {
        _decimals = escrows[_orderId].currency.decimals();
        }

        // Validations Premium
        if (!escrows[_orderId].taker_premium) {
            //get amountFeeTaker
            _amountFeeTaker = ((escrows[_orderId].value *
                (escrows[_orderId].takerfee * 10 ** _decimals)) /
                (100 * 10 ** _decimals)) / 1000;
        }

        return _amountFeeTaker;
    }

    /**
     * @notice  Get Amount Fee Maker
     * @param   _orderId  .
     * @param   _native  .
     * @return  uint256  .
     */
    function getAmountFeeMaker(
        uint256 _orderId,
        bool _native
    ) private view returns (uint256) {
        //get decimal of stable
        uint8 _decimals = 18;
        uint256 _amountFeeMaker = 0;

        if (_native == false) {
            _decimals = escrows[_orderId].currency.decimals();
        }

        // Validations Premium
        if (!escrows[_orderId].maker_premium) {
            //get amountFeeTaker
            _amountFeeMaker =
                ((escrows[_orderId].value *
                    (escrows[_orderId].makerfee * 10 ** _decimals)) /
                    (100 * 10 ** _decimals)) /
                1000;
        }

        return _amountFeeMaker;
    }
    // ================== End Private functions ==================
}