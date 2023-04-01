// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success,) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage)
        internal
        returns (bytes memory)
    {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage)
        internal
        returns (bytes memory)
    {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage)
        internal
        view
        returns (bytes memory)
    {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage)
        internal
        returns (bytes memory)
    {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(bool success, bytes memory returndata, string memory errorMessage)
        internal
        pure
        returns (bytes memory)
    {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IMultiVesting {
    function Affiliate() external view returns (address);

    function AffiliateEarnings() external view returns (uint256);

    function MizuRegistry() external view returns (address);

    function ReferralEarnings(address) external view returns (uint256);

    function Router() external view returns (address);

    function admin() external view returns (address);

    function bondInfo(address) external view returns (uint256 nonce);

    function claimAffiliate() external;

    function claimReferral(address _referrer) external;

    function currentDebt() external view returns (uint256 currentDebt_);

    function currentDebtID(uint256 _vestingID) external view returns (uint256 currentDebt_);

    function currentMizuFee() external view returns (uint256 currentFee_);

    function customTreasury() external view returns (address);

    function debtDecayAll() external view returns (uint256 totalDecay_);

    function debtDecayID(uint256 _vestingID) external view returns (uint256 decay_);

    function debtRatio(uint256 _vestingID) external view returns (uint256 debtRatio_);

    function deposit(uint256 _amount, address _depositor, address _referrer, uint256 _vestingID, uint256 _minBonus)
        external
        returns (uint256);

    function factory() external view returns (address);

    function getBonus(uint256 _ID) external view returns (uint256 bonus_);

    function getMizuTreasury() external view returns (address mizuTreasury);

    function getPayout(uint256 _amountIn, uint256 _vestingID) external view returns (uint256 payout_);

    function getTerms()
        external
        view
        returns (
            uint256[10] memory vestings_,
            uint256[10] memory bonuses_,
            uint256 maxPayout_,
            uint256[10] memory maxDebts_
        );

    function initializeBond(
        uint256[10] memory _vestingTerms,
        uint256[10] calldata _bonus,
        uint256 _maxPayout,
        uint256[10] calldata _maxDebt
    ) external;

    function isLpBond() external view returns (bool);

    function isPriceVariable() external view returns (bool);

    function lastDecay() external view returns (uint256);

    function maxDebt(uint256 _vestingID) external view returns (uint256);

    function maxPayout() external view returns (uint256);

    function minBonus() external view returns (uint256);

    function payinToken() external view returns (address);

    function payoutToken() external view returns (address);

    function pendingPayoutFor(address _depositor, uint256 _vestingID) external view returns (uint256 pendingPayout_);

    function percentVestedFor(address _depositor, uint256 _vestingID) external view returns (uint256 percentVested_);

    function quoteToken() external view returns (address);

    function redeem(address _depositor, uint256 _vestingID) external returns (uint256);

    function setAffiliate(address _affiliate) external;

    function setBondBonuses(uint256[10] calldata _bonuses) external;

    function setBondMaxDebt(uint256[10] calldata _maxDebt) external;

    function setBondMaxPayout(uint256 _maxPayout) external;

    function setBondMinBonus(uint256 _minBonus) external;

    function setBondTerms(
        uint256[10] memory _vestings,
        uint256[10] memory _bonuses,
        uint256 _minBonus,
        uint256 _maxPayout,
        uint256[10] memory _maxDebt,
        bool _isVariable
    ) external;

    function setBondTermsByVestingId(uint256 _vestingID, uint256 _vesting, uint256 _bonus, uint256 _maxDebt) external;

    function setBondVestings(uint256[10] memory _vestings) external;

    function setSlippageRatio(uint256 _slippageRatio) external;

    function slippageRatio() external view returns (uint256);

    function terms() external view returns (uint256 maxPayout);

    function totalDebt() external view returns (uint256 totalDebt_);

    function totalDebts(uint256) external view returns (uint256);

    function totalPayinBonded() external view returns (uint256);

    function totalPayoutGiven() external view returns (uint256);

    function transferManagment(address _newOwner) external;

    function updateQuoteToken(address _newQuoteToken) external;

    function updateRouter(address _newRouter) external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.17;

interface IRegistry {
    function AFFILIATE_ROLE() external view returns (bytes32);

    function AffPercentage(address) external view returns (uint256);

    function AffWhitelist(address) external view returns (bool);

    function BaseAffPerc() external view returns (uint256);

    function BaseRefPerc() external view returns (uint256);

    function CustomRefPerc(address) external view returns (uint256);

    function DEFAULT_ADMIN_ROLE() external view returns (bytes32);

    function FACTORY_ROLE() external view returns (bytes32);

    function FEE_DECIMALS() external view returns (uint256);

    function MAX_FEE() external view returns (uint256);

    function MizuDao() external view returns (address);

    function MizuTreasury() external view returns (address);

    function REFERRAL_ROLE() external view returns (bytes32);

    function SETFEE_ROLE() external view returns (bytes32);

    function addFactory(address _factory) external;

    function bondDetails(uint256)
        external
        view
        returns (
            address _payoutToken,
            address _principleToken,
            address _treasuryAddress,
            address _bondAddress,
            address _initialOwner,
            address _factory
        );

    function bondTypeFee(address) external view returns (uint256);

    function claimAllAff(address _affiliate) external;

    function claimAllRef(address _referrer) external;

    function factories(uint256) external view returns (address);

    function feeDiscount(address) external view returns (uint256);

    function getAffiliate(address _affiliate) external view returns (uint256 _percentage);

    function getFee(address _bond) external view returns (uint256 _checkedFee);

    function getRefPerc(address _referrer) external view returns (uint256 _percentage);

    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    function getRoleMemberCount(bytes32 role) external view returns (uint256);

    function grantRole(bytes32 role, address account) external;

    function hasRole(bytes32 role, address account) external view returns (bool);

    function indexOfBond(address) external view returns (uint256);

    function pushBond(
        address _payoutToken,
        address _principleToken,
        address _customTreasury,
        address _customBond,
        address _initialOwner,
        address _factory
    ) external returns (address _treasury, address _bond);

    function renounceRole(bytes32 role, address account) external;

    function resetFeeDiscount(address _bondOwner) external;

    function revokeRole(bytes32 role, address account) external;

    function setAffPerc(address _affiliate, uint256 _percentage) external;

    function setAffWhitelist(address _affiliate, bool _bool) external;

    function setBaseAffPerc(uint256 _percentage) external;

    function setBaseRefPerc(uint256 _percentage) external;

    function setBondTypeFees(address _factory, uint256 _fee) external;

    function setFeeDiscount(address _bondOwner, uint256 _newFeeDiscount) external;

    function setMizuDAO(address _mizuDao) external;

    function setMizuTreasury(address _mizuTreasury) external;

    function setRefPerc(address _referrer, uint256 _percentage) external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.17;

contract Ownable {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function transferManagment(address _newOwner) external onlyOwner {
        require(_newOwner != address(0));
        owner = _newOwner;
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.17;

import "./lib/Ownable.sol";
import "./lib/int/IRegistry.sol";
import "./lib/int/IMultiVesting.sol";
import "./utils/AccessControl.sol";

contract Registry is AccessControl {
    /* ======== ROLES ======== */

    bytes32 public constant SETFEE_ROLE = keccak256("SETFEE_ROLE"); //can set custom fees for bonds
    bytes32 public constant AFFILIATE_ROLE = keccak256("AFFILIATE_ROLE"); //can whitelist and change affiliate fees
    bytes32 public constant REFERRAL_ROLE = keccak256("REFERRAL_ROLE"); //can change referral fees
    bytes32 public constant FACTORY_ROLE = keccak256("FACTORY_ROLE"); //can push new bonds & bonds details

    /* ======== STRUCTS ======== */

    struct BondDetails {
        address _payoutToken;
        address _principleToken;
        address _treasuryAddress;
        address _bondAddress;
        address _initialOwner;
        address _factory;
    }

    /* ======== STATE VARIABLES ======== */

    address public MizuDao;
    address public MizuTreasury; // receiver of Mizu fees
    address[] public factories; // array of Mizu factories
    BondDetails[] public bondDetails; //stores info of bonds
    mapping(address => uint256) public indexOfBond;
    mapping(address => bool) public verifiedOwner;

    /* ======== FEE VARIABLES ======== */

    mapping(address => uint256) public bondTypeFee; // use different fees for different factory
    mapping(address => uint256) public feeDiscount; // discounts the bond fees for bond owners 100%=1000
    uint256 public constant MAX_FEE = 50000; // 5%
    uint256 public constant FEE_DECIMALS = 1000000; //100%

    /* ======== AFFILIATE VARIABLES ======== */

    mapping(address => bool) public AffWhitelist;
    mapping(address => uint256) public AffPercentage;
    uint256 public BaseAffPerc;

    /* ======== REFERRAL VARIABLES ======== */

    mapping(address => uint256) public CustomRefPerc;
    uint256 public BaseRefPerc;

    /* ======== EVENTS ======== */

    event BondCreation(address treasury, address bond, address _initialOwner);

    /* ======== CONSTRUCTOR ======== */

    constructor(address _mizuDao, address _mizuTreasury) {
        require(_mizuDao != address(0));
        MizuDao = _mizuDao;
        require(_mizuTreasury != address(0));
        MizuTreasury = _mizuTreasury;

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, _mizuDao);
        _setupRole(DEFAULT_ADMIN_ROLE, address(this)); // used to automatically give factory roles
    }
    /* ======== FACTORY FUNCTIONS ======== */

    /**
     * @notice pushes bond details to array
     *     @param _payoutToken address
     *     @param _principleToken address
     *     @param _customTreasury address
     *     @param _customBond address
     *     @param _initialOwner address
     *     @return _treasury address
     *     @return _bond address
     */
    function pushBond(
        address _payoutToken,
        address _principleToken,
        address _customTreasury,
        address _customBond,
        address _initialOwner,
        address _factory
    ) external returns (address _treasury, address _bond) {
        require(hasRole(FACTORY_ROLE, msg.sender) || hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not FACTORY role"); //ONLY FACTORY ROLE

        indexOfBond[_customBond] = bondDetails.length;

        bondDetails.push(
            BondDetails({
                _payoutToken: _payoutToken,
                _principleToken: _principleToken,
                _treasuryAddress: _customTreasury,
                _bondAddress: _customBond,
                _initialOwner: _initialOwner,
                _factory: _factory
            })
        );

        emit BondCreation(_customTreasury, _customBond, _initialOwner);
        return (_customTreasury, _customBond);
    }

    /* ======== ADMIN FUNCTIONS ======== */

    function setVerifiedBondOwner(address _bondOwner, bool _isVerified) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not ADMIN role"); //ONLY ADMIN ROLE
        verifiedOwner[_bondOwner] = _isVerified;
    }

    function setMizuDAO(address _mizuDao) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not ADMIN role"); //ONLY ADMIN ROLE
        require(_mizuDao != address(0));
        MizuDao = _mizuDao;
    }

    function setMizuTreasury(address _mizuTreasury) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not ADMIN role"); //ONLY ADMIN ROLE
        require(_mizuTreasury != address(0));
        MizuTreasury = _mizuTreasury;
    }

    function addFactory(address _factory) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not ADMIN role"); //ONLY ADMIN ROLE
        bool found = false;
        for (uint256 i = 0; i < factories.length; i++) {
            //check if factory is already in array
            if (factories[i] == _factory) {
                found = true;
                break;
            }
        }
        if (!found) {
            //add the factory if it doesnt exists already
            factories.push(_factory);
            grantRole(0xdfbefbf47cfe66b701d8cfdbce1de81c821590819cb07e71cb01b6602fb0ee27, _factory);
        }
    }

    /* ======== FEE FUNCTIONS ======== */

    function setFeeDiscount(address _bond, uint256 _newFeeDiscount) external {
        require(hasRole(SETFEE_ROLE, msg.sender) || hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not SETFEE role");
        require(_bond != address(0), "address zero");
        require(_newFeeDiscount <= 1000, "over 100%"); //_newFeeDiscount needs to be lower than 100%
        feeDiscount[_bond] = _newFeeDiscount; //update fee mapping for bondOwner address
    }

    function resetFeeDiscount(address _bondOwner) external {
        // ONLY SETFEE ROLE Reset the value to the default value.
        require(hasRole(SETFEE_ROLE, msg.sender) || hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not SETFEE role");
        delete feeDiscount[_bondOwner];
    }

    function setBondTypeFees(address _factory, uint256 _fee) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not ADMIN role"); //ONLY ADMIN ROLE
        require(_fee <= MAX_FEE, "Fee too high");

        bool isFactory = false;
        for (uint256 i = 0; i < factories.length; i++) {
            //check if factory is already in array
            if (factories[i] == _factory) {
                isFactory = true;
                break;
            }
        }
        if (isFactory) {
            //add the factory if it doesnt exists already
            bondTypeFee[_factory] = _fee;
        }
    }

    /* ======== VIEW FUNCTIONS ======== */

    function getBondLists(address _factory) public view returns(BondDetails[] memory bondList_) {
            if (_factory != address(0)) {
                uint index;
                bondList_ = new BondDetails[](bondDetails.length);
                for (uint i = 0; i < bondDetails.length; i++) {
                    if (bondDetails[i]._factory == _factory) {
                        bondList_[index] = bondDetails[i];
                        index++;
                    }
                }
            } else {
            bondList_ = new BondDetails[](bondDetails.length);
            bondList_ = bondDetails;
        }
    }

    function isBondVerified(address _bond) public view returns(bool){
        if(!isBond(_bond)){
            return false;
        } else {
            if (verifiedOwner[IMultiVesting(_bond).admin()]) {
                return true;
            } else {
                return false;
            }
        }
    }

    function getBondsOfOwner(address _owner) public view returns(address[] memory bonds_){
        uint256 index;
        for (uint256 i = 0; i < bondDetails.length; i++) {
            address bond = (bondDetails[i]._bondAddress);
            bonds_ = new address[](bondDetails.length);
            if (IMultiVesting(bond).admin() == _owner){
                bonds_[index] = (bondDetails[i]._bondAddress);
                index = index++;
            }
        } 
    }

    function getFee(address _bond) external view returns (uint256 _checkedFee) {
        uint256 bondID = indexOfBond[_bond];
        address bondOwner = IMultiVesting(_bond).admin();
        uint256 typeFee = bondTypeFee[bondDetails[bondID]._factory];
        if (bondID == 0) {
            if (bondDetails[bondID]._bondAddress == _bond) {
                //avoid false false positive when bondID=0
                if (feeDiscount[bondOwner] == 0) {
                    //check if feeDiscount = 0
                    _checkedFee = typeFee; //use typeFee if _feeDiscount = 0
                } else {
                    _checkedFee = typeFee - (typeFee * (feeDiscount[bondOwner]) / 1000);
                }
            } else {
                revert();
            }
        } else {
            if (feeDiscount[bondOwner] == 0) {
                //check if feeDiscount = 0
                _checkedFee = typeFee; //use typeFee if _feeDiscount = 0
            } else {
                _checkedFee = typeFee - (typeFee * (feeDiscount[bondOwner]) / 1000);
            }
        }
    }

    function getAffiliate(address _affiliate) external view returns (uint256 _percentage) {
        if (AffPercentage[_affiliate] != 0) {
            _percentage = AffPercentage[_affiliate];
        } else {
            _percentage = BaseAffPerc;
        }
        return (_percentage);
    }

    function getRefPerc(address _referrer) external view returns (uint256 _percentage) {
        if (CustomRefPerc[_referrer] != 0 && CustomRefPerc[_referrer] > BaseRefPerc) {
            _percentage = CustomRefPerc[_referrer];
        } else {
            _percentage = BaseRefPerc;
        }
        return _percentage;
    }

    function isBond(address _bond) public view returns (bool) {
        bool _isBond = false;
        for (uint256 i = 0; i < bondDetails.length; i++) {
            if (_bond != bondDetails[i]._bondAddress) {
                _isBond = false;
                continue;
            } else {
                _isBond = true;
                break;
            }
        }
        return _isBond;
    }

    /* ======== AFFILIATE FUNCTIONS ======== */

    //function map whitelisted addresses (only affiliate role)
    function setAffWhitelist(address _affiliate, bool _bool) external {
        require(hasRole(AFFILIATE_ROLE, msg.sender) || hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not AFFILIATE role"); //ONLY AFFILIATE ROLE
        AffWhitelist[_affiliate] = _bool;
    }

    //function only admin set baseAffPerc;
    function setBaseAffPerc(uint256 _percentage) external {
        require(_percentage <= 1000000, "over 100%");
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not ADMIN role"); //ONLY ADMIN ROLE
        BaseAffPerc = _percentage;
    }

    function setAffPerc(address _affiliate, uint256 _percentage) external {
        require(_percentage <= 1000000, "over 100%");
        require(hasRole(AFFILIATE_ROLE, msg.sender) || hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not AFFILIATE role"); //ONLY ADMIN ROLE
        AffPercentage[_affiliate] = _percentage;
    }

    function claimAllAff(address _affiliate) external {
        for (uint256 i = 0; i < bondDetails.length; i++) {
            IMultiVesting bond = IMultiVesting(bondDetails[i]._bondAddress);
            uint256 earnings = bond.AffiliateEarnings();
            if (bond.Affiliate() == _affiliate && earnings > 0) {
                bond.claimAffiliate();
            }
        }
    }

    /* ======== REFERRAL FUNCTIONS ======== */

    //function map custom referral percentual for an addresses (only ref role)
    function setRefPerc(address _referrer, uint256 _percentage) external {
        require(_percentage <= 1000000, "over 100%");
        require(hasRole(REFERRAL_ROLE, msg.sender) || hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not REFERRAL role"); //ONLY REFERRAL ROLE
        CustomRefPerc[_referrer] = _percentage;
    }

    function setBaseRefPerc(uint256 _percentage) external {
        require(_percentage <= 1000000, "over 100%");
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not ADMIN role"); //ONLY ADMIN ROLE
        BaseRefPerc = _percentage;
    }

    function claimAllRef(address _referrer) external {
        for (uint256 i = 0; i < bondDetails.length; i++) {
            IMultiVesting bond = IMultiVesting(bondDetails[i]._bondAddress);
            uint256 earnings = bond.ReferralEarnings(_referrer);
            if (earnings > 0) {
                bond.claimReferral(_referrer);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./EnumerableSet.sol";
import "../lib/Address.sol";
import "./Context.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;

    struct RoleData {
        EnumerableSet.AddressSet members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}