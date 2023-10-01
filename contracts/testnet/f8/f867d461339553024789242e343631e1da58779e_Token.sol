// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { ERC20BaseInternal } from "@solidstate/contracts/token/ERC20/base/ERC20BaseInternal.sol";
import { SolidStateERC20 } from "@solidstate/contracts/token/ERC20/SolidStateERC20.sol";

import { IToken } from "./IToken.sol";
import { TokenInternal } from "./TokenInternal.sol";
import { AccrualData } from "./types/DataTypes.sol";

/// @title Token contract
/// @dev contains all externally called functions and necessary override for the Token facet
contract Token is TokenInternal, SolidStateERC20, IToken {
    /// @inheritdoc IToken
    function accrualData(
        address account
    ) external view returns (AccrualData memory data) {
        data = _accrualData(account);
    }

    /// @inheritdoc IToken
    function addMintingContract(address account) external onlyOwner {
        _addMintingContract(account);
    }

    /// @notice overrides _beforeTokenTransfer hook to enforce non-transferability
    /// @param from sender of tokens
    /// @param to receiver of tokens
    /// @param amount quantity of tokens transferred
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20BaseInternal, TokenInternal) {
        super._beforeTokenTransfer(from, to, amount);
    }

    /// @inheritdoc IToken
    function BASIS() external pure returns (uint32 value) {
        value = _BASIS();
    }

    /// @inheritdoc IToken
    function burn(
        address account,
        uint256 amount
    ) external onlyMintingContract {
        _burn(amount, account);
    }

    /// @inheritdoc IToken
    function claim() external {
        _claim(msg.sender);
    }

    /// @inheritdoc IToken
    function claimableTokens(
        address account
    ) external view returns (uint256 amount) {
        amount = _claimableTokens(account);
    }

    /// @inheritdoc IToken
    function disperseTokens(
        address[] calldata recipients,
        uint256[] calldata amounts
    ) external onlyOwner {
        _disperseTokens(recipients, amounts);
    }

    /// @inheritdoc IToken
    function distributionFractionBP()
        external
        view
        returns (uint32 fractionBP)
    {
        fractionBP = _distributionFractionBP();
    }

    /// @inheritdoc IToken
    function distributionSupply() external view returns (uint256 supply) {
        supply = _distributionSupply();
    }

    /// @inheritdoc IToken
    function globalRatio() external view returns (uint256 ratio) {
        ratio = _globalRatio();
    }

    /// @inheritdoc IToken
    function mint(
        address account,
        uint256 amount
    ) external onlyMintingContract {
        _mint(amount, account);
    }

    /// @inheritdoc IToken
    function mintingContracts()
        external
        view
        returns (address[] memory contracts)
    {
        contracts = _mintingContracts();
    }

    /// @inheritdoc IToken
    function removeMintingContract(address account) external onlyOwner {
        _removeMintingContract(account);
    }

    /// @inheritdoc IToken
    function SCALE() external pure returns (uint256 value) {
        value = _SCALE();
    }

    /// @inheritdoc IToken
    function setDistributionFractionBP(
        uint32 _distributionFractionBP
    ) external onlyOwner {
        _setDistributionFractionBP(_distributionFractionBP);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC20BaseInternal } from './IERC20BaseInternal.sol';
import { ERC20BaseStorage } from './ERC20BaseStorage.sol';

/**
 * @title Base ERC20 internal functions, excluding optional extensions
 */
abstract contract ERC20BaseInternal is IERC20BaseInternal {
    /**
     * @notice query the total minted token supply
     * @return token supply
     */
    function _totalSupply() internal view virtual returns (uint256) {
        return ERC20BaseStorage.layout().totalSupply;
    }

    /**
     * @notice query the token balance of given account
     * @param account address to query
     * @return token balance
     */
    function _balanceOf(
        address account
    ) internal view virtual returns (uint256) {
        return ERC20BaseStorage.layout().balances[account];
    }

    /**
     * @notice query the allowance granted from given holder to given spender
     * @param holder approver of allowance
     * @param spender recipient of allowance
     * @return token allowance
     */
    function _allowance(
        address holder,
        address spender
    ) internal view virtual returns (uint256) {
        return ERC20BaseStorage.layout().allowances[holder][spender];
    }

    /**
     * @notice enable spender to spend tokens on behalf of holder
     * @param holder address on whose behalf tokens may be spent
     * @param spender recipient of allowance
     * @param amount quantity of tokens approved for spending
     * @return success status (always true; otherwise function should revert)
     */
    function _approve(
        address holder,
        address spender,
        uint256 amount
    ) internal virtual returns (bool) {
        if (holder == address(0)) revert ERC20Base__ApproveFromZeroAddress();
        if (spender == address(0)) revert ERC20Base__ApproveToZeroAddress();

        ERC20BaseStorage.layout().allowances[holder][spender] = amount;

        emit Approval(holder, spender, amount);

        return true;
    }

    /**
     * @notice decrease spend amount granted by holder to spender
     * @param holder address on whose behalf tokens may be spent
     * @param spender address whose allowance to decrease
     * @param amount quantity by which to decrease allowance
     */
    function _decreaseAllowance(
        address holder,
        address spender,
        uint256 amount
    ) internal {
        uint256 allowance = _allowance(holder, spender);

        if (amount > allowance) revert ERC20Base__InsufficientAllowance();

        unchecked {
            _approve(holder, spender, allowance - amount);
        }
    }

    /**
     * @notice mint tokens for given account
     * @param account recipient of minted tokens
     * @param amount quantity of tokens minted
     */
    function _mint(address account, uint256 amount) internal virtual {
        if (account == address(0)) revert ERC20Base__MintToZeroAddress();

        _beforeTokenTransfer(address(0), account, amount);

        ERC20BaseStorage.Layout storage l = ERC20BaseStorage.layout();
        l.totalSupply += amount;
        l.balances[account] += amount;

        emit Transfer(address(0), account, amount);
    }

    /**
     * @notice burn tokens held by given account
     * @param account holder of burned tokens
     * @param amount quantity of tokens burned
     */
    function _burn(address account, uint256 amount) internal virtual {
        if (account == address(0)) revert ERC20Base__BurnFromZeroAddress();

        _beforeTokenTransfer(account, address(0), amount);

        ERC20BaseStorage.Layout storage l = ERC20BaseStorage.layout();
        uint256 balance = l.balances[account];
        if (amount > balance) revert ERC20Base__BurnExceedsBalance();
        unchecked {
            l.balances[account] = balance - amount;
        }
        l.totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    /**
     * @notice transfer tokens from holder to recipient
     * @param holder owner of tokens to be transferred
     * @param recipient beneficiary of transfer
     * @param amount quantity of tokens transferred
     * @return success status (always true; otherwise function should revert)
     */
    function _transfer(
        address holder,
        address recipient,
        uint256 amount
    ) internal virtual returns (bool) {
        if (holder == address(0)) revert ERC20Base__TransferFromZeroAddress();
        if (recipient == address(0)) revert ERC20Base__TransferToZeroAddress();

        _beforeTokenTransfer(holder, recipient, amount);

        ERC20BaseStorage.Layout storage l = ERC20BaseStorage.layout();
        uint256 holderBalance = l.balances[holder];
        if (amount > holderBalance) revert ERC20Base__TransferExceedsBalance();
        unchecked {
            l.balances[holder] = holderBalance - amount;
        }
        l.balances[recipient] += amount;

        emit Transfer(holder, recipient, amount);

        return true;
    }

    /**
     * @notice transfer tokens to given recipient on behalf of given holder
     * @param holder holder of tokens prior to transfer
     * @param recipient beneficiary of token transfer
     * @param amount quantity of tokens to transfer
     * @return success status (always true; otherwise function should revert)
     */
    function _transferFrom(
        address holder,
        address recipient,
        uint256 amount
    ) internal virtual returns (bool) {
        _decreaseAllowance(holder, msg.sender, amount);

        _transfer(holder, recipient, amount);

        return true;
    }

    /**
     * @notice ERC20 hook, called before all transfers including mint and burn
     * @dev function should be overridden and new implementation must call super
     * @param from sender of tokens
     * @param to receiver of tokens
     * @param amount quantity of tokens transferred
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { ISolidStateERC20 } from './ISolidStateERC20.sol';
import { ERC20Base } from './base/ERC20Base.sol';
import { ERC20Extended } from './extended/ERC20Extended.sol';
import { ERC20Metadata } from './metadata/ERC20Metadata.sol';
import { ERC20MetadataInternal } from './metadata/ERC20MetadataInternal.sol';
import { ERC20Permit } from './permit/ERC20Permit.sol';
import { ERC20PermitInternal } from './permit/ERC20PermitInternal.sol';

/**
 * @title SolidState ERC20 implementation, including recommended extensions
 */
abstract contract SolidStateERC20 is
    ISolidStateERC20,
    ERC20Base,
    ERC20Extended,
    ERC20Metadata,
    ERC20Permit
{
    function _setName(
        string memory name
    ) internal virtual override(ERC20MetadataInternal, ERC20PermitInternal) {
        super._setName(name);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { ISolidStateERC20 } from "@solidstate/contracts/token/ERC20/ISolidStateERC20.sol";
import { AccrualData } from "./types/DataTypes.sol";

/// @title ITokenMint interface
/// @dev contains all external functions for Token facet
interface IToken is ISolidStateERC20 {
    /// @notice returns AccrualData struct pertaining to account, which contains Token accrual
    /// information
    /// @param account address of account
    /// @return data AccrualData of account
    function accrualData(
        address account
    ) external view returns (AccrualData memory data);

    /// @notice adds an account to the mintingContracts enumerable set
    /// @param account address of account
    function addMintingContract(address account) external;

    /// @notice returns the value of BASIS
    /// @return value BASIS value
    function BASIS() external pure returns (uint32 value);

    /// @notice burns an amount of tokens of an account
    /// @param account account to burn from
    /// @param amount amount of tokens to burn
    function burn(address account, uint256 amount) external;

    /// @notice claims all claimable tokens for the msg.sender
    function claim() external;

    /// @notice returns all claimable tokens of a given account
    /// @param account address of account
    /// @return amount amount of claimable tokens
    function claimableTokens(
        address account
    ) external view returns (uint256 amount);

    /// @notice Disperses tokens to a list of recipients
    /// @param recipients assumed ordered array of recipient addresses
    /// @param amounts assumed ordered array of token amounts to disperse
    function disperseTokens(
        address[] calldata recipients,
        uint256[] calldata amounts
    ) external;

    /// @notice returns the distributionFractionBP value
    /// @return fractionBP value of distributionFractionBP
    function distributionFractionBP() external view returns (uint32 fractionBP);

    /// @notice returns the distribution supply value
    /// @return supply distribution supply value
    function distributionSupply() external view returns (uint256 supply);

    /// @notice returns the global ratio value
    /// @return ratio global ratio value
    function globalRatio() external view returns (uint256 ratio);

    /// @notice disburses (mints) an amount of tokens to an account
    /// @param account address of account receive the tokens
    /// @param amount amount of tokens to disburse
    function mint(address account, uint256 amount) external;

    /// @notice returns all addresses of contracts which are allowed to call mint/burn
    /// @return contracts array of addresses of contracts which are allowed to call mint/burn
    function mintingContracts()
        external
        view
        returns (address[] memory contracts);

    /// @notice removes an account from the mintingContracts enumerable set
    /// @param account address of account
    function removeMintingContract(address account) external;

    /// @notice returns the value of SCALE
    /// @return value SCALE value
    function SCALE() external pure returns (uint256 value);

    /// @notice sets a new value for distributionFractionBP
    /// @param _distributionFractionBP new distributionFractionBP value
    function setDistributionFractionBP(uint32 _distributionFractionBP) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { OwnableInternal } from "@solidstate/contracts/access/ownable/OwnableInternal.sol";
import { EnumerableSet } from "@solidstate/contracts/data/EnumerableSet.sol";
import { ERC20BaseInternal } from "@solidstate/contracts/token/ERC20/base/ERC20BaseInternal.sol";

import { ITokenInternal } from "./ITokenInternal.sol";
import { TokenStorage as Storage } from "./Storage.sol";
import { AccrualData } from "./types/DataTypes.sol";
import { GuardsInternal } from "../../common/GuardsInternal.sol";

/// @title $MINT Token contract
/// @dev The internal functionality of $MINT token.
abstract contract TokenInternal is
    ERC20BaseInternal,
    GuardsInternal,
    ITokenInternal,
    OwnableInternal
{
    using EnumerableSet for EnumerableSet.AddressSet;

    // used for floating point calculations
    uint256 private constant SCALE = 10 ** 36;
    // used for fee calculations - not sufficient for floating point calculations
    uint32 private constant BASIS = 1000000000;

    /// @notice modifier to only allow addresses contained in mintingContracts
    /// to call modified function
    modifier onlyMintingContract() {
        if (!Storage.layout().mintingContracts.contains(msg.sender))
            revert NotMintingContract();
        _;
    }

    /// @notice returns AccrualData struct pertaining to account, which contains Token accrual
    /// information
    /// @param account address of account
    /// @return data AccrualData of account
    function _accrualData(
        address account
    ) internal view returns (AccrualData memory data) {
        data = Storage.layout().accrualData[account];
    }

    /// @notice accrues the tokens available for claiming for an account
    /// @param l TokenStorage Layout struct
    /// @param account address of account
    /// @return accountData accrualData of given account
    function _accrueTokens(
        Storage.Layout storage l,
        address account
    ) internal returns (AccrualData storage accountData) {
        accountData = l.accrualData[account];

        // calculate claimable tokens
        uint256 accruedTokens = _scaleDown(
            (l.globalRatio - accountData.offset) * _balanceOf(account)
        );

        // update account's last ratio
        accountData.offset = l.globalRatio;

        // update claimable tokens
        accountData.accruedTokens += accruedTokens;
    }

    /// @notice adds an account to the mintingContracts enumerable set
    /// @param account address of account
    function _addMintingContract(address account) internal {
        Storage.layout().mintingContracts.add(account);
        emit MintingContractAdded(account);
    }

    /// @notice returns the value of BASIS
    /// @return value BASIS value
    function _BASIS() internal pure returns (uint32 value) {
        value = BASIS;
    }

    /// @notice overrides _beforeTokenTransfer hook to enforce non-transferability
    /// @param from sender of tokens
    /// @param to receiver of tokens
    /// @param amount quantity of tokens transferred
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        if (from != address(0) && from != address(this)) {
            if (to != address(0)) {
                revert NonTransferable();
            }
        }
    }

    /// @notice burns an amount of tokens of an account
    /// @dev parameter ordering is reversed to remove clash with ERC20BaseInternal burn(address,uint256)
    /// @param amount amount of tokens to burn
    /// @param account account to burn from
    function _burn(uint256 amount, address account) internal {
        Storage.Layout storage l = Storage.layout();

        _accrueTokens(l, account);
        _burn(account, amount);
    }

    /// @notice claims all claimable tokens for an account
    /// @param account address of account
    function _claim(address account) internal {
        Storage.Layout storage l = Storage.layout();

        // accrue tokens prior to claim
        AccrualData storage accountData = _accrueTokens(l, account);

        uint256 accruedTokens = accountData.accruedTokens;

        // decrease distribution supply by claimed tokens
        l.distributionSupply -= accruedTokens;

        // set accruedTokens of account to 0
        accountData.accruedTokens = 0;

        _transfer(address(this), account, accruedTokens);
    }

    /// @notice returns all claimable tokens of a given account
    /// @param account address of account
    /// @return amount amount of claimable tokens
    function _claimableTokens(
        address account
    ) internal view returns (uint256 amount) {
        Storage.Layout storage l = Storage.layout();
        AccrualData storage accountData = l.accrualData[account];

        amount =
            _scaleDown(
                (l.globalRatio - accountData.offset) * _balanceOf(account)
            ) +
            accountData.accruedTokens;
    }

    /// @notice Disperses tokens to a list of recipients
    /// @param recipients assumed ordered array of recipient addresses
    /// @param amounts assumed ordered array of token amounts to disperse
    function _disperseTokens(
        address[] calldata recipients,
        uint256[] calldata amounts
    ) internal {
        for (uint256 i = 0; i < recipients.length; ++i) {
            require(_transfer(address(this), recipients[i], amounts[i]));
        }
    }

    /// @notice returns the distributionFractionBP value
    /// @return fractionBP value of distributionFractionBP
    function _distributionFractionBP()
        internal
        view
        returns (uint32 fractionBP)
    {
        fractionBP = Storage.layout().distributionFractionBP;
    }

    /// @notice returns the distribution supply value
    /// @return supply distribution supply value
    function _distributionSupply() internal view returns (uint256 supply) {
        supply = Storage.layout().distributionSupply;
    }

    /// @notice returns the global ratio value
    /// @return ratio global ratio value
    function _globalRatio() internal view returns (uint256 ratio) {
        ratio = Storage.layout().globalRatio;
    }

    /// @notice mint an amount of tokens to an account
    /// @dev parameter ordering is reversed to remove clash with ERC20BaseInternal mint(address,uint256)
    /// @param amount amount of tokens to disburse
    /// @param account address of account receive the tokens
    function _mint(uint256 amount, address account) internal {
        Storage.Layout storage l = Storage.layout();

        // calculate amount for distribution
        uint256 distributionAmount = (amount * l.distributionFractionBP) /
            BASIS;

        // decrease amount to mint to account
        amount -= distributionAmount;

        uint256 accountBalance = _balanceOf(account);
        uint256 totalSupply = _totalSupply();
        uint256 supplyDelta = totalSupply -
            accountBalance -
            l.distributionSupply;
        uint256 accruedTokens;

        AccrualData storage accountData = l.accrualData[account];

        // if the supplyDelta is zero, it means there are no tokens in circulation
        // so the receiving account is the first/only receiver therefore is owed the full
        // distribution amount.
        // to ensure the full distribution amount is given to an account in this instance,
        // the account offset for said account should not be updated
        if (supplyDelta > 0) {
            // tokens are accrued for account prior to global ratio or offset being updated
            accruedTokens = _scaleDown(
                (l.globalRatio - accountData.offset) * accountBalance
            );

            // update global ratio
            l.globalRatio += _scaleUp(distributionAmount) / supplyDelta;

            // update account offset
            accountData.offset = l.globalRatio;

            // update claimable tokens
            accountData.accruedTokens += accruedTokens;
        } else {
            // calculation ratio of distributionAmount to remaining amount
            uint256 distributionRatio = _scaleUp(distributionAmount) / amount;

            // check whether the sole holder is the first minter because if so
            // the globalRatio will be a multiple of distributionRatio
            if (l.globalRatio % distributionRatio == 0) {
                // update globalRatio
                l.globalRatio += distributionRatio;
                // update account offset
                accountData.offset = l.globalRatio - distributionRatio;
            } else {
                // sole holder due to all other minters burning tokens
                // calculate and accrue previous token accrual
                uint256 previousAccruals = _scaleDown(
                    (l.globalRatio - accountData.offset) * accountBalance
                );
                accountData.accruedTokens +=
                    distributionAmount +
                    previousAccruals;
                // update globalRatio
                l.globalRatio += distributionRatio;
                // update account offset
                accountData.offset = l.globalRatio;
            }
        }

        l.distributionSupply += distributionAmount;

        // mint tokens to contract and account
        _mint(address(this), distributionAmount);
        _mint(account, amount);
    }

    /// @notice returns all addresses of contracts which are allowed to call mint/burn
    /// @return contracts array of addresses of contracts which are allowed to call mint/burn
    function _mintingContracts()
        internal
        view
        returns (address[] memory contracts)
    {
        contracts = Storage.layout().mintingContracts.toArray();
    }

    /// @notice removes an account from the mintingContracts enumerable set
    /// @param account address of account
    function _removeMintingContract(address account) internal {
        Storage.layout().mintingContracts.remove(account);
        emit MintingContractRemoved(account);
    }

    /// @notice returns the value of SCALE
    /// @return value SCALE value
    function _SCALE() internal pure returns (uint256 value) {
        value = SCALE;
    }

    /// @notice multiplies a value by the scale, to enable floating point calculations
    /// @param value value to be scaled up
    /// @return scaledValue product of value and scale
    function _scaleUp(
        uint256 value
    ) internal pure returns (uint256 scaledValue) {
        scaledValue = value * SCALE;
    }

    /// @notice divides a value by the scale, to rectify a previous scaleUp operation
    /// @param value value to be scaled down
    /// @return scaledValue value divided by scale
    function _scaleDown(
        uint256 value
    ) internal pure returns (uint256 scaledValue) {
        scaledValue = value / SCALE;
    }

    /// @notice sets a new value for distributionFractionBP
    /// @param distributionFractionBP new distributionFractionBP value
    function _setDistributionFractionBP(
        uint32 distributionFractionBP
    ) internal {
        _enforceBasis(distributionFractionBP, BASIS);

        Storage.layout().distributionFractionBP = distributionFractionBP;
        emit DistributionFractionSet(distributionFractionBP);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

/// @dev DataTypes.sol defines the Token struct data types used in the TokenStorage layout

/// @dev represents data related to $MINT token accruals (linked to a specific account)
struct AccrualData {
    /// @dev last ratio an account had when one of their actions led to a change in the
    /// reservedSupply
    uint256 offset;
    /// @dev amount of tokens accrued as a result of distribution to token holders
    uint256 accruedTokens;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC20Internal } from '../../../interfaces/IERC20Internal.sol';

/**
 * @title ERC20 base interface
 */
interface IERC20BaseInternal is IERC20Internal {
    error ERC20Base__ApproveFromZeroAddress();
    error ERC20Base__ApproveToZeroAddress();
    error ERC20Base__BurnExceedsBalance();
    error ERC20Base__BurnFromZeroAddress();
    error ERC20Base__InsufficientAllowance();
    error ERC20Base__MintToZeroAddress();
    error ERC20Base__TransferExceedsBalance();
    error ERC20Base__TransferFromZeroAddress();
    error ERC20Base__TransferToZeroAddress();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

library ERC20BaseStorage {
    struct Layout {
        mapping(address => uint256) balances;
        mapping(address => mapping(address => uint256)) allowances;
        uint256 totalSupply;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.ERC20Base');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC20Base } from './base/IERC20Base.sol';
import { IERC20Extended } from './extended/IERC20Extended.sol';
import { IERC20Metadata } from './metadata/IERC20Metadata.sol';
import { IERC20Permit } from './permit/IERC20Permit.sol';

interface ISolidStateERC20 is
    IERC20Base,
    IERC20Extended,
    IERC20Metadata,
    IERC20Permit
{}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC20 } from '../../../interfaces/IERC20.sol';
import { IERC20Base } from './IERC20Base.sol';
import { ERC20BaseInternal } from './ERC20BaseInternal.sol';
import { ERC20BaseStorage } from './ERC20BaseStorage.sol';

/**
 * @title Base ERC20 implementation, excluding optional extensions
 */
abstract contract ERC20Base is IERC20Base, ERC20BaseInternal {
    /**
     * @inheritdoc IERC20
     */
    function totalSupply() external view returns (uint256) {
        return _totalSupply();
    }

    /**
     * @inheritdoc IERC20
     */
    function balanceOf(address account) external view returns (uint256) {
        return _balanceOf(account);
    }

    /**
     * @inheritdoc IERC20
     */
    function allowance(
        address holder,
        address spender
    ) external view returns (uint256) {
        return _allowance(holder, spender);
    }

    /**
     * @inheritdoc IERC20
     */
    function approve(address spender, uint256 amount) external returns (bool) {
        return _approve(msg.sender, spender, amount);
    }

    /**
     * @inheritdoc IERC20
     */
    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool) {
        return _transfer(msg.sender, recipient, amount);
    }

    /**
     * @inheritdoc IERC20
     */
    function transferFrom(
        address holder,
        address recipient,
        uint256 amount
    ) external returns (bool) {
        return _transferFrom(holder, recipient, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC20Extended } from './IERC20Extended.sol';
import { ERC20ExtendedInternal } from './ERC20ExtendedInternal.sol';

/**
 * @title ERC20 safe approval extensions
 * @dev mitigations for transaction-ordering vulnerability (see https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729)
 */
abstract contract ERC20Extended is IERC20Extended, ERC20ExtendedInternal {
    /**
     * @inheritdoc IERC20Extended
     */
    function increaseAllowance(
        address spender,
        uint256 amount
    ) external returns (bool) {
        return _increaseAllowance(spender, amount);
    }

    /**
     * @inheritdoc IERC20Extended
     */
    function decreaseAllowance(
        address spender,
        uint256 amount
    ) external returns (bool) {
        return _decreaseAllowance(spender, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC20Metadata } from './IERC20Metadata.sol';
import { ERC20MetadataInternal } from './ERC20MetadataInternal.sol';

/**
 * @title ERC20 metadata extensions
 */
abstract contract ERC20Metadata is IERC20Metadata, ERC20MetadataInternal {
    /**
     * @inheritdoc IERC20Metadata
     */
    function name() external view returns (string memory) {
        return _name();
    }

    /**
     * @inheritdoc IERC20Metadata
     */
    function symbol() external view returns (string memory) {
        return _symbol();
    }

    /**
     * @inheritdoc IERC20Metadata
     */
    function decimals() external view returns (uint8) {
        return _decimals();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC20MetadataInternal } from './IERC20MetadataInternal.sol';
import { ERC20MetadataStorage } from './ERC20MetadataStorage.sol';

/**
 * @title ERC20Metadata internal functions
 */
abstract contract ERC20MetadataInternal is IERC20MetadataInternal {
    /**
     * @notice return token name
     * @return token name
     */
    function _name() internal view virtual returns (string memory) {
        return ERC20MetadataStorage.layout().name;
    }

    /**
     * @notice return token symbol
     * @return token symbol
     */
    function _symbol() internal view virtual returns (string memory) {
        return ERC20MetadataStorage.layout().symbol;
    }

    /**
     * @notice return token decimals, generally used only for display purposes
     * @return token decimals
     */
    function _decimals() internal view virtual returns (uint8) {
        return ERC20MetadataStorage.layout().decimals;
    }

    function _setName(string memory name) internal virtual {
        ERC20MetadataStorage.layout().name = name;
    }

    function _setSymbol(string memory symbol) internal virtual {
        ERC20MetadataStorage.layout().symbol = symbol;
    }

    function _setDecimals(uint8 decimals) internal virtual {
        ERC20MetadataStorage.layout().decimals = decimals;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import { ERC20Base } from '../base/ERC20Base.sol';
import { ERC20Metadata } from '../metadata/ERC20Metadata.sol';
import { ERC20PermitInternal } from './ERC20PermitInternal.sol';
import { ERC20PermitStorage } from './ERC20PermitStorage.sol';
import { IERC2612 } from './IERC2612.sol';
import { IERC20Permit } from './IERC20Permit.sol';

/**
 * @title ERC20 extension with support for ERC2612 permits
 * @dev derived from https://github.com/soliditylabs/ERC20-Permit (MIT license)
 */
abstract contract ERC20Permit is IERC20Permit, ERC20PermitInternal {
    /**
     * @inheritdoc IERC2612
     */
    function DOMAIN_SEPARATOR()
        external
        view
        returns (bytes32 domainSeparator)
    {
        return _DOMAIN_SEPARATOR();
    }

    /**
     * @inheritdoc IERC2612
     */
    function nonces(address owner) public view returns (uint256) {
        return _nonces(owner);
    }

    /**
     * @inheritdoc IERC2612
     */
    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        _permit(owner, spender, amount, deadline, v, r, s);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import { ECDSA } from '../../../cryptography/ECDSA.sol';
import { EIP712 } from '../../../cryptography/EIP712.sol';
import { ERC20BaseInternal } from '../base/ERC20BaseInternal.sol';
import { ERC20MetadataInternal } from '../metadata/ERC20MetadataInternal.sol';
import { ERC20PermitStorage } from './ERC20PermitStorage.sol';
import { IERC20PermitInternal } from './IERC20PermitInternal.sol';

/**
 * @title ERC20 extension with support for ERC2612 permits
 * @dev derived from https://github.com/soliditylabs/ERC20-Permit (MIT license)
 */
abstract contract ERC20PermitInternal is
    ERC20BaseInternal,
    ERC20MetadataInternal,
    IERC20PermitInternal
{
    using ECDSA for bytes32;

    bytes32 internal constant EIP712_TYPE_HASH =
        keccak256(
            'Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)'
        );

    /**
     * @notice return the EIP-712 domain separator unique to contract and chain
     * @return domainSeparator domain separator
     */
    function _DOMAIN_SEPARATOR()
        internal
        view
        returns (bytes32 domainSeparator)
    {
        domainSeparator = ERC20PermitStorage.layout().domainSeparators[
            block.chainid
        ];

        if (domainSeparator == 0x00) {
            domainSeparator = EIP712.calculateDomainSeparator(
                keccak256(bytes(_name())),
                keccak256(bytes(_version()))
            );
        }
    }

    /**
     * @notice get the current ERC2612 nonce for the given address
     * @return current nonce
     */
    function _nonces(address owner) internal view returns (uint256) {
        return ERC20PermitStorage.layout().nonces[owner];
    }

    /**
     * @notice query signing domain version
     * @return version signing domain version
     */
    function _version() internal view virtual returns (string memory version) {
        version = '1';
    }

    /**
     * @notice approve spender to transfer tokens held by owner via signature
     * @dev this function may be vulnerable to approval replay attacks
     * @param owner holder of tokens and signer of permit
     * @param spender beneficiary of approval
     * @param amount quantity of tokens to approve
     * @param v secp256k1 'v' value
     * @param r secp256k1 'r' value
     * @param s secp256k1 's' value
     */
    function _permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal virtual {
        if (deadline < block.timestamp) revert ERC20Permit__ExpiredDeadline();

        ERC20PermitStorage.Layout storage l = ERC20PermitStorage.layout();

        // execute EIP-712 hashStruct procedure using assembly, equavalent to:
        //
        // bytes32 structHash = keccak256(
        //   abi.encode(
        //     EIP712_TYPE_HASH,
        //     owner,
        //     spender,
        //     amount,
        //     nonce,
        //     deadline
        //   )
        // );

        bytes32 structHash;
        uint256 nonce = l.nonces[owner];

        bytes32 typeHash = EIP712_TYPE_HASH;

        assembly {
            // load free memory pointer
            let pointer := mload(64)

            mstore(pointer, typeHash)
            mstore(add(pointer, 32), owner)
            mstore(add(pointer, 64), spender)
            mstore(add(pointer, 96), amount)
            mstore(add(pointer, 128), nonce)
            mstore(add(pointer, 160), deadline)

            structHash := keccak256(pointer, 192)
        }

        bytes32 domainSeparator = l.domainSeparators[block.chainid];

        if (domainSeparator == 0x00) {
            domainSeparator = EIP712.calculateDomainSeparator(
                keccak256(bytes(_name())),
                keccak256(bytes(_version()))
            );
            l.domainSeparators[block.chainid] = domainSeparator;
        }

        // recreate and hash data payload using assembly, equivalent to:
        //
        // bytes32 hash = keccak256(
        //   abi.encodePacked(
        //     uint16(0x1901),
        //     domainSeparator,
        //     structHash
        //   )
        // );

        bytes32 hash;

        assembly {
            // load free memory pointer
            let pointer := mload(64)

            // this magic value is the EIP-191 signed data header, consisting of
            // the hardcoded 0x19 and the one-byte version 0x01
            mstore(
                pointer,
                0x1901000000000000000000000000000000000000000000000000000000000000
            )
            mstore(add(pointer, 2), domainSeparator)
            mstore(add(pointer, 34), structHash)

            hash := keccak256(pointer, 66)
        }

        // validate signature

        address signer = hash.recover(v, r, s);

        if (signer != owner) revert ERC20Permit__InvalidSignature();

        l.nonces[owner]++;
        _approve(owner, spender, amount);
    }

    /**
     * @inheritdoc ERC20MetadataInternal
     * @notice set new token name and invalidate cached domain separator
     * @dev domain separator is not immediately recalculated, and will ultimately depend on the output of the _name view function
     */
    function _setName(string memory name) internal virtual override {
        // TODO: cache invalidation can fail if chainid is reverted to a previous value
        super._setName(name);
        delete ERC20PermitStorage.layout().domainSeparators[block.chainid];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC173 } from '../../interfaces/IERC173.sol';
import { AddressUtils } from '../../utils/AddressUtils.sol';
import { IOwnableInternal } from './IOwnableInternal.sol';
import { OwnableStorage } from './OwnableStorage.sol';

abstract contract OwnableInternal is IOwnableInternal {
    using AddressUtils for address;

    modifier onlyOwner() {
        if (msg.sender != _owner()) revert Ownable__NotOwner();
        _;
    }

    modifier onlyTransitiveOwner() {
        if (msg.sender != _transitiveOwner())
            revert Ownable__NotTransitiveOwner();
        _;
    }

    function _owner() internal view virtual returns (address) {
        return OwnableStorage.layout().owner;
    }

    function _transitiveOwner() internal view virtual returns (address owner) {
        owner = _owner();

        while (owner.isContract()) {
            try IERC173(owner).owner() returns (address transitiveOwner) {
                owner = transitiveOwner;
            } catch {
                break;
            }
        }
    }

    function _transferOwnership(address account) internal virtual {
        _setOwner(account);
    }

    function _setOwner(address account) internal virtual {
        OwnableStorage.Layout storage l = OwnableStorage.layout();
        emit OwnershipTransferred(l.owner, account);
        l.owner = account;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title Set implementation with enumeration functions
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts (MIT license)
 */
library EnumerableSet {
    error EnumerableSet__IndexOutOfBounds();

    struct Set {
        bytes32[] _values;
        // 1-indexed to allow 0 to signify nonexistence
        mapping(bytes32 => uint256) _indexes;
    }

    struct Bytes32Set {
        Set _inner;
    }

    struct AddressSet {
        Set _inner;
    }

    struct UintSet {
        Set _inner;
    }

    function at(
        Bytes32Set storage set,
        uint256 index
    ) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    function at(
        AddressSet storage set,
        uint256 index
    ) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    function at(
        UintSet storage set,
        uint256 index
    ) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    function contains(
        Bytes32Set storage set,
        bytes32 value
    ) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    function contains(
        AddressSet storage set,
        address value
    ) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    function contains(
        UintSet storage set,
        uint256 value
    ) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    function indexOf(
        Bytes32Set storage set,
        bytes32 value
    ) internal view returns (uint256) {
        return _indexOf(set._inner, value);
    }

    function indexOf(
        AddressSet storage set,
        address value
    ) internal view returns (uint256) {
        return _indexOf(set._inner, bytes32(uint256(uint160(value))));
    }

    function indexOf(
        UintSet storage set,
        uint256 value
    ) internal view returns (uint256) {
        return _indexOf(set._inner, bytes32(value));
    }

    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function add(
        Bytes32Set storage set,
        bytes32 value
    ) internal returns (bool) {
        return _add(set._inner, value);
    }

    function add(
        AddressSet storage set,
        address value
    ) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    function remove(
        Bytes32Set storage set,
        bytes32 value
    ) internal returns (bool) {
        return _remove(set._inner, value);
    }

    function remove(
        AddressSet storage set,
        address value
    ) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    function remove(
        UintSet storage set,
        uint256 value
    ) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    function toArray(
        Bytes32Set storage set
    ) internal view returns (bytes32[] memory) {
        return set._inner._values;
    }

    function toArray(
        AddressSet storage set
    ) internal view returns (address[] memory) {
        bytes32[] storage values = set._inner._values;
        address[] storage array;

        assembly {
            array.slot := values.slot
        }

        return array;
    }

    function toArray(
        UintSet storage set
    ) internal view returns (uint256[] memory) {
        bytes32[] storage values = set._inner._values;
        uint256[] storage array;

        assembly {
            array.slot := values.slot
        }

        return array;
    }

    function _at(
        Set storage set,
        uint256 index
    ) private view returns (bytes32) {
        if (index >= set._values.length)
            revert EnumerableSet__IndexOutOfBounds();
        return set._values[index];
    }

    function _contains(
        Set storage set,
        bytes32 value
    ) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    function _indexOf(
        Set storage set,
        bytes32 value
    ) private view returns (uint256) {
        unchecked {
            return set._indexes[value] - 1;
        }
    }

    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    function _add(
        Set storage set,
        bytes32 value
    ) private returns (bool status) {
        if (!_contains(set, value)) {
            set._values.push(value);
            set._indexes[value] = set._values.length;
            status = true;
        }
    }

    function _remove(
        Set storage set,
        bytes32 value
    ) private returns (bool status) {
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            unchecked {
                bytes32 last = set._values[set._values.length - 1];

                // move last value to now-vacant index

                set._values[valueIndex - 1] = last;
                set._indexes[last] = valueIndex;
            }
            // clear last index

            set._values.pop();
            delete set._indexes[value];

            status = true;
        }
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

/// @title ITokenMintInternal interface
/// @dev contains all errors and events used in the Token facet contract
interface ITokenInternal {
    /// @notice thrown when attempting to transfer tokens and the from address is neither
    /// the zero-address, nor the contract address, or the to address is not the zero address
    error NonTransferable();

    /// @notice thrown when an addrss not contained in mintingContracts attempts to mint or burn
    /// tokens
    error NotMintingContract();

    /// @notice emitted when a new distributionFractionBP value is set
    /// @param distributionFractionBP the new distributionFractionBP value
    event DistributionFractionSet(uint32 distributionFractionBP);

    /// @notice emitted when an account is added to mintingContracts
    /// @param account address of account
    event MintingContractAdded(address account);

    /// @notice emitted when an account is removed from mintingContracts
    /// @param account address of account
    event MintingContractRemoved(address account);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { AccrualData } from "./types/DataTypes.sol";
import { EnumerableSet } from "@solidstate/contracts/data/EnumerableSet.sol";

/// @title TokenStorage
/// @dev defines storage layout for the Token facet
library TokenStorage {
    struct Layout {
        /// @dev ratio of distributionSupply to totalSupply
        uint256 globalRatio;
        /// @dev number of tokens held for distribution to token holders
        uint256 distributionSupply;
        /// @dev fraction of tokens to be reserved for distribution to token holders in basis points
        uint32 distributionFractionBP;
        /// @dev information related to Token accruals for an account
        mapping(address account => AccrualData data) accrualData;
        /// @dev set of contracts which are allowed to call the mint function
        EnumerableSet.AddressSet mintingContracts;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("insrt.contracts.storage.MintToken");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { IGuardsInternal } from "./IGuardsInternal.sol";

/// @title GuardsInternal contract
/// @dev contains common internal guard functions
abstract contract GuardsInternal is IGuardsInternal {
    /// @notice enforces that a value does not exceed the basis
    /// @param value value to check
    function _enforceBasis(uint32 value, uint32 basis) internal pure {
        if (value > basis) {
            revert BasisExceeded();
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title Partial ERC20 interface needed by internal functions
 */
interface IERC20Internal {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC20 } from '../../../interfaces/IERC20.sol';
import { IERC20BaseInternal } from './IERC20BaseInternal.sol';

/**
 * @title ERC20 base interface
 */
interface IERC20Base is IERC20BaseInternal, IERC20 {

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC20ExtendedInternal } from './IERC20ExtendedInternal.sol';

/**
 * @title ERC20 extended interface
 */
interface IERC20Extended is IERC20ExtendedInternal {
    /**
     * @notice increase spend amount granted to spender
     * @param spender address whose allowance to increase
     * @param amount quantity by which to increase allowance
     * @return success status (always true; otherwise function will revert)
     */
    function increaseAllowance(
        address spender,
        uint256 amount
    ) external returns (bool);

    /**
     * @notice decrease spend amount granted to spender
     * @param spender address whose allowance to decrease
     * @param amount quantity by which to decrease allowance
     * @return success status (always true; otherwise function will revert)
     */
    function decreaseAllowance(
        address spender,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC20MetadataInternal } from './IERC20MetadataInternal.sol';

/**
 * @title ERC20 metadata interface
 */
interface IERC20Metadata is IERC20MetadataInternal {
    /**
     * @notice return token name
     * @return token name
     */
    function name() external view returns (string memory);

    /**
     * @notice return token symbol
     * @return token symbol
     */
    function symbol() external view returns (string memory);

    /**
     * @notice return token decimals, generally used only for display purposes
     * @return token decimals
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC20Metadata } from '../metadata/IERC20Metadata.sol';
import { IERC2612 } from './IERC2612.sol';
import { IERC20PermitInternal } from './IERC20PermitInternal.sol';

// TODO: note that IERC20Metadata is needed for eth-permit library

interface IERC20Permit is IERC20PermitInternal, IERC2612 {

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC20Internal } from './IERC20Internal.sol';

/**
 * @title ERC20 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-20
 */
interface IERC20 is IERC20Internal {
    /**
     * @notice query the total minted token supply
     * @return token supply
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice query the token balance of given account
     * @param account address to query
     * @return token balance
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @notice query the allowance granted from given holder to given spender
     * @param holder approver of allowance
     * @param spender recipient of allowance
     * @return token allowance
     */
    function allowance(
        address holder,
        address spender
    ) external view returns (uint256);

    /**
     * @notice grant approval to spender to spend tokens
     * @dev prefer ERC20Extended functions to avoid transaction-ordering vulnerability (see https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729)
     * @param spender recipient of allowance
     * @param amount quantity of tokens approved for spending
     * @return success status (always true; otherwise function should revert)
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @notice transfer tokens to given recipient
     * @param recipient beneficiary of token transfer
     * @param amount quantity of tokens to transfer
     * @return success status (always true; otherwise function should revert)
     */
    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @notice transfer tokens to given recipient on behalf of given holder
     * @param holder holder of tokens prior to transfer
     * @param recipient beneficiary of token transfer
     * @param amount quantity of tokens to transfer
     * @return success status (always true; otherwise function should revert)
     */
    function transferFrom(
        address holder,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { ERC20BaseInternal, ERC20BaseStorage } from '../base/ERC20Base.sol';
import { IERC20ExtendedInternal } from './IERC20ExtendedInternal.sol';

/**
 * @title ERC20 safe approval extensions
 * @dev mitigations for transaction-ordering vulnerability (see https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729)
 */
abstract contract ERC20ExtendedInternal is
    ERC20BaseInternal,
    IERC20ExtendedInternal
{
    /**
     * @notice increase spend amount granted to spender
     * @param spender address whose allowance to increase
     * @param amount quantity by which to increase allowance
     * @return success status (always true; otherwise function will revert)
     */
    function _increaseAllowance(
        address spender,
        uint256 amount
    ) internal virtual returns (bool) {
        uint256 allowance = _allowance(msg.sender, spender);

        unchecked {
            if (allowance > allowance + amount)
                revert ERC20Extended__ExcessiveAllowance();

            return _approve(msg.sender, spender, allowance + amount);
        }
    }

    /**
     * @notice decrease spend amount granted to spender
     * @param spender address whose allowance to decrease
     * @param amount quantity by which to decrease allowance
     * @return success status (always true; otherwise function will revert)
     */
    function _decreaseAllowance(
        address spender,
        uint256 amount
    ) internal virtual returns (bool) {
        _decreaseAllowance(msg.sender, spender, amount);

        return true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title ERC20 metadata internal interface
 */
interface IERC20MetadataInternal {

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

library ERC20MetadataStorage {
    struct Layout {
        string name;
        string symbol;
        uint8 decimals;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.ERC20Metadata');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

library ERC20PermitStorage {
    struct Layout {
        mapping(address => uint256) nonces;
        // Mapping of ChainID to domain separators. This is a very gas efficient way
        // to not recalculate the domain separator on every call, while still
        // automatically detecting ChainID changes.
        mapping(uint256 => bytes32) domainSeparators;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.ERC20Permit');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC2612Internal } from './IERC2612Internal.sol';

/**
 * @title ERC2612 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-2612.
 */
interface IERC2612 is IERC2612Internal {
    /**
     * @notice return the EIP-712 domain separator unique to contract and chain
     * @return domainSeparator domain separator
     */
    function DOMAIN_SEPARATOR() external view returns (bytes32 domainSeparator);

    /**
     * @notice get the current ERC2612 nonce for the given address
     * @return current nonce
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @notice approve spender to transfer tokens held by owner via signature
     * @dev this function may be vulnerable to approval replay attacks
     * @param owner holder of tokens and signer of permit
     * @param spender beneficiary of approval
     * @param amount quantity of tokens to approve
     * @param v secp256k1 'v' value
     * @param r secp256k1 'r' value
     * @param s secp256k1 's' value
     */
    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title Elliptic Curve Digital Signature Algorithm (ECDSA) operations
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts (MIT license)
 */
library ECDSA {
    error ECDSA__InvalidS();
    error ECDSA__InvalidSignature();
    error ECDSA__InvalidSignatureLength();
    error ECDSA__InvalidV();

    /**
     * @notice recover signer of hashed message from signature
     * @param hash hashed data payload
     * @param signature signed data payload
     * @return recovered message signer
     */
    function recover(
        bytes32 hash,
        bytes memory signature
    ) internal pure returns (address) {
        if (signature.length != 65) revert ECDSA__InvalidSignatureLength();

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        return recover(hash, v, r, s);
    }

    /**
     * @notice recover signer of hashed message from signature v, r, and s values
     * @param hash hashed data payload
     * @param v signature "v" value
     * @param r signature "r" value
     * @param s signature "s" value
     * @return recovered message signer
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (
            uint256(s) >
            0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0
        ) revert ECDSA__InvalidS();
        if (v != 27 && v != 28) revert ECDSA__InvalidV();

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) revert ECDSA__InvalidSignature();

        return signer;
    }

    /**
     * @notice generate an "Ethereum Signed Message" in the format returned by the eth_sign JSON-RPC method
     * @param hash hashed data payload
     * @return signed message hash
     */
    function toEthSignedMessageHash(
        bytes32 hash
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked('\x19Ethereum Signed Message:\n32', hash)
            );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title EIP-712 typed structured data hashing and signing
 * @dev see https://eips.ethereum.org/EIPS/eip-712
 */
library EIP712 {
    bytes32 internal constant EIP712_TYPE_HASH =
        keccak256(
            'EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'
        );

    /**
     * @notice calculate unique EIP-712 domain separator
     * @dev name and version inputs are hashed as required by EIP-712 because they are of dynamic-length types
     * @dev implementation of EIP712Domain struct type excludes the optional salt parameter
     * @param nameHash hash of human-readable signing domain name
     * @param versionHash hash of signing domain version
     * @return domainSeparator domain separator
     */
    function calculateDomainSeparator(
        bytes32 nameHash,
        bytes32 versionHash
    ) internal view returns (bytes32 domainSeparator) {
        // execute EIP-712 hashStruct procedure using assembly, equavalent to:
        //
        // domainSeparator = keccak256(
        //   abi.encode(
        //     EIP712_TYPE_HASH,
        //     nameHash,
        //     versionHash,
        //     block.chainid,
        //     address(this)
        //   )
        // );

        bytes32 typeHash = EIP712_TYPE_HASH;

        assembly {
            // load free memory pointer
            let pointer := mload(64)

            mstore(pointer, typeHash)
            mstore(add(pointer, 32), nameHash)
            mstore(add(pointer, 64), versionHash)
            mstore(add(pointer, 96), chainid())
            mstore(add(pointer, 128), address())

            domainSeparator := keccak256(pointer, 160)
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC2612Internal } from './IERC2612Internal.sol';

interface IERC20PermitInternal is IERC2612Internal {
    error ERC20Permit__ExpiredDeadline();
    error ERC20Permit__InvalidSignature();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC173Internal } from './IERC173Internal.sol';

/**
 * @title Contract ownership standard interface
 * @dev see https://eips.ethereum.org/EIPS/eip-173
 */
interface IERC173 is IERC173Internal {
    /**
     * @notice get the ERC173 contract owner
     * @return contract owner
     */
    function owner() external view returns (address);

    /**
     * @notice transfer contract ownership to new account
     * @param account address of new owner
     */
    function transferOwnership(address account) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { UintUtils } from './UintUtils.sol';

library AddressUtils {
    using UintUtils for uint256;

    error AddressUtils__InsufficientBalance();
    error AddressUtils__NotContract();
    error AddressUtils__SendValueFailed();

    function toString(address account) internal pure returns (string memory) {
        return uint256(uint160(account)).toHexString(20);
    }

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable account, uint256 amount) internal {
        (bool success, ) = account.call{ value: amount }('');
        if (!success) revert AddressUtils__SendValueFailed();
    }

    function functionCall(
        address target,
        bytes memory data
    ) internal returns (bytes memory) {
        return
            functionCall(target, data, 'AddressUtils: failed low-level call');
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory error
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, error);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                'AddressUtils: failed low-level call with value'
            );
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory error
    ) internal returns (bytes memory) {
        if (value > address(this).balance)
            revert AddressUtils__InsufficientBalance();
        return _functionCallWithValue(target, data, value, error);
    }

    /**
     * @notice execute arbitrary external call with limited gas usage and amount of copied return data
     * @dev derived from https://github.com/nomad-xyz/ExcessivelySafeCall (MIT License)
     * @param target recipient of call
     * @param gasAmount gas allowance for call
     * @param value native token value to include in call
     * @param maxCopy maximum number of bytes to copy from return data
     * @param data encoded call data
     * @return success whether call is successful
     * @return returnData copied return data
     */
    function excessivelySafeCall(
        address target,
        uint256 gasAmount,
        uint256 value,
        uint16 maxCopy,
        bytes memory data
    ) internal returns (bool success, bytes memory returnData) {
        returnData = new bytes(maxCopy);

        assembly {
            // execute external call via assembly to avoid automatic copying of return data
            success := call(
                gasAmount,
                target,
                value,
                add(data, 0x20),
                mload(data),
                0,
                0
            )

            // determine whether to limit amount of data to copy
            let toCopy := returndatasize()

            if gt(toCopy, maxCopy) {
                toCopy := maxCopy
            }

            // store the length of the copied bytes
            mstore(returnData, toCopy)

            // copy the bytes from returndata[0:toCopy]
            returndatacopy(add(returnData, 0x20), 0, toCopy)
        }
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory error
    ) private returns (bytes memory) {
        if (!isContract(target)) revert AddressUtils__NotContract();

        (bool success, bytes memory returnData) = target.call{ value: value }(
            data
        );

        if (success) {
            return returnData;
        } else if (returnData.length > 0) {
            assembly {
                let returnData_size := mload(returnData)
                revert(add(32, returnData), returnData_size)
            }
        } else {
            revert(error);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC173Internal } from '../../interfaces/IERC173Internal.sol';

interface IOwnableInternal is IERC173Internal {
    error Ownable__NotOwner();
    error Ownable__NotTransitiveOwner();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

library OwnableStorage {
    struct Layout {
        address owner;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.Ownable');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

/// @title IGuardsInternal interface
/// @dev interface holding all errors related to common guards
interface IGuardsInternal {
    /// @notice thrown when attempting to set a value larger than basis
    error BasisExceeded();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC20BaseInternal } from '../base/IERC20BaseInternal.sol';

/**
 * @title ERC20 extended internal interface
 */
interface IERC20ExtendedInternal is IERC20BaseInternal {
    error ERC20Extended__ExcessiveAllowance();
    error ERC20Extended__InsufficientAllowance();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

interface IERC2612Internal {}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title Partial ERC173 interface needed by internal functions
 */
interface IERC173Internal {
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title utility functions for uint256 operations
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts/ (MIT license)
 */
library UintUtils {
    error UintUtils__InsufficientHexLength();

    bytes16 private constant HEX_SYMBOLS = '0123456789abcdef';

    function add(uint256 a, int256 b) internal pure returns (uint256) {
        return b < 0 ? sub(a, -b) : a + uint256(b);
    }

    function sub(uint256 a, int256 b) internal pure returns (uint256) {
        return b < 0 ? add(a, -b) : a - uint256(b);
    }

    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return '0';
        }

        uint256 temp = value;
        uint256 digits;

        while (temp != 0) {
            digits++;
            temp /= 10;
        }

        bytes memory buffer = new bytes(digits);

        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }

        return string(buffer);
    }

    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return '0x00';
        }

        uint256 length = 0;

        for (uint256 temp = value; temp != 0; temp >>= 8) {
            unchecked {
                length++;
            }
        }

        return toHexString(value, length);
    }

    function toHexString(
        uint256 value,
        uint256 length
    ) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = '0';
        buffer[1] = 'x';

        unchecked {
            for (uint256 i = 2 * length + 1; i > 1; --i) {
                buffer[i] = HEX_SYMBOLS[value & 0xf];
                value >>= 4;
            }
        }

        if (value != 0) revert UintUtils__InsufficientHexLength();

        return string(buffer);
    }
}