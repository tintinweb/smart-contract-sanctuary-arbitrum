// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title IERC20PluriMethods
 * @notice Extends the IERC20 interface with additional functionality for Pluri tokens.
 **/
interface IERC20PluriMethods is IERC20 {
    function mint(address to, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function isActiveMinter(address account) external view returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function TAX() external view returns (uint256);
}

/**
 * @title Pluri Token Staking Contract
 * @dev This contract is used to stake Pluri tokens and distribute rewards to stakers and the faucet.
 * Features: 
 *       - Automatic distrubution of Pluri for users and stakers.
 *       - Automatic self regulating quantity of Pluri minted to balance inflation.
 *       - Taxes from Pluri contract are divided among stakeholders, and users whom claim from the faucet.
 *       - Orphaned contract to prevent rule changes.
 *       - Stakeholder rug pull prevention, stakeholders won't be able to unstake in mass. Every 30 days, a max potential amount of unstakes are generated. 8% of the epochs stakeholders at time of calculation. Minimum of 30 days required to have the oppurtunity to unstake.
 *             Example, if there are 12 stakeholders, only 1 will be allowed to unstake within 30 days. Then when the 30 days is up, another staker is allowed to unstake for that 30 days. First come first serve. 
 *       
 *       - Tokens that are distrubuted via mints do not contain transaction history, while tokens collected from taxes will be decoupled from their transaction histroy.   
 *       - Incase of an urgent exploit(s), the contract will be removed of it's mint status from the Pluri token contract and a new stakeholder and faucet contract will be deployed allowing updates. Stakeholders will be able to unstake immediatly if this occurs and mints will no longer occur protecting financial stability.
 *       - Anybody can earn Pluri by using the faucet, costing only the native tokens gas amount.
 *
 * How does the tokenomics work?
 *     Definitions:
 *              - Wait List    | A queue that tracks the order, staked and unstaked stakeholders
 *              - Epoch        | A list genreated from the wait list, tracks whom to distrubute rewards to.
 *              - Faucet       | A seperate contract that is always the last stakeholder in the lists. Provides the public the ability to claim Pluri (Call auto mint function)
 *              - Tax          | Collected tax from data transactions from Pluri contract.
 *              - Staking      | To lock 21,000 Pluri tokens within the staking contract for 30 days minimum, earning more Pluri in the process. 
 *              - Unstake      | To withdrawl 21,000 Pluri from the staking contract, no longer earning stakeholder rewards.
 *              - Faucet Claim | The ability to use the faucet to earn Pluri. Each claim is generated in 60 second intervals.
 *              - Gas          | Fee required to successfully conduct a transaction or execute a contract with the chains native token.
 *              - Tax reward   | The stakeholders contract balance of Pluri divided by epoch list size (balance of pluri / epoch stakeholder count)
 *     Proccess:          
 *          1. 11 people and the faucet become stakeholders
 *          2. The 12 stakeholders are entered into the wait list
 *          3. An epoch is generated and copys the wait list order of stakeholders
 *          4. The tax reward is determined (balance of pluri in stakeholder contract / epoch stakeholder count), if tax reward cannot be given evenly, no tax reward will be given
 *          5. Every 60 seconds a possible faucet claim is generated
 *          6. A public user triggers a faucet claim, paying a small transaction fee (gas)
 *          7. The epoch then picks whose turn it is to receive rewards based on the order
 *          8. 1 Pluri is minted to the selected stakeholder and tax rewards are transferred
 *          9. The public user is minted (1 / epoch list size) of Pluri, and (tax reward / epoch list size) of tax reward is transferred to the public user
 *          (Repeat 5-8 until it's faucets turn)
 *          10. When a public user triggers a faucet claim, when it's the faucets turn in the epoch, no Pluri is minted to the faucet. The public user recieves minted (1 / epoch list size) of Pluri, and (tax reward / epoch list size) of tax reward transferred, with a bonus remainder value for the minted and tax
 *          11. After reaching the faucet's turn, the epoch ends, and the cycle starts over from step 3
 *
 *   Visual of exampele distribution:
 *     
 *          Epoch list size = 12
 *          Stakeholder contract balance of Tax = 0.0000014 Pluri
 *          Stakeholder Reward (SR) = 1 Pluri
 *          Claim Reward (CR) = 0.0833... Pluri  ( / epoch list size)
 *          Claim Reward Remainder (CRR) = 0.000000000000000004 Pluri  (1 % epoch list size)
 *
 *          Tax Reward (TR) = 0.0000001 Pluri  ( Stakeholder contract balance of Tax / epoch list size)
 *          Faucet Tax Reward (FTR) = 0.000000008333... Pluri (Tax Reward / epoch list size)
 *          Faucet Tax Reward Remainder (FTRR) = 0.000000000000000004 Pluri (FTR % epoch list size)
 *
 *          (P) - Pluri Token
 *          S Reward - Stakeholder base reward
 *          ST Reward - Stakeholder tax reward
 *
 *          U Reward - Public User base reward
 *          UT Reward - Public User tax reward
 *           
 *          Epoch Rewards for Stakeholders
 *  Stakeholders  | user1, user2, user3, user4, user5, user6, user7, user8, user9, user10, user11, faucet |
 *      S Reward  | SR     SR     SR     SR     SR     SR     SR     SR     SR     SR      SR      0
 *     ST Reward  | TR     TR     TR     TR     TR     TR     TR     TR     TR     TR      TR      0
 *
 *          Epoch Rewards for public people that claim at the faucet
 *  Public Claims | person1, person2, person3, person4, person5, person6, person7, person8, person9, person10, person11, person12 |
 *              U | CR       CR       CR       CR       CR       CR       CR       CR       CR       CR        CR        CR + CRR
 *             UT | FTR      FTR      FTR      FTR      FTR      FTR      FTR      FTR      FTR      FTR       FTR       FTR + FTRR
 **/
contract PluriStaking is Ownable{
    IERC20PluriMethods private pluriToken;

    event Staked(address indexed staker, uint256 amount, uint256 timestamp);
    event Unstaked(address indexed unstaker, uint256 amount, uint256 timestamp);    
    event RewardsDistributed(address indexed recipient, uint256 mintedReward, uint256 taxReward, uint256 timestamp, RewardType rewardType);
    event FaucetAddressInitialized(address indexed newFaucetAddress, uint256 timestamp);
    event EpochStarted(uint256 numberOfStakeholders, uint256 timestamp);

    
    address public faucetAddress;
    
    /// @notice Struct to store stakeholder information.
    /// @dev Since Pluri is automatically distrubuted to stakers, earnings is used only for informational purposes.
    struct StakeHolder {
        uint256 stakedAt;
        uint256 index;
        uint256 earnings;
    }

    struct EpochStakeHolder {
        address stakerAddress;
        uint256 stakedAt;
    }

    /// @notice Struct to represent an epoch in the staking process.
    struct Epoch {
        EpochStakeHolder[] stakeholders;
        uint256 currentIndex;
        uint256 epochSize;
    }

    /// @notice Enum for different types of rewards.
    enum RewardType { Staker, Faucet }

    uint256 public constant STAKING_AMOUNT = 21000 * 10 ** 18; // assuming 18 decimals
    uint256 public constant MINT_AMOUNT = 1 * 10 ** 18;
    uint256 public constant LOCKIN_TIME = 30 days; 
    uint256 public lastAutoMintTimestamp;
    uint256 public lastContainerTimestamp = 0;
    uint256 public currentUnstakeLimit = 0;
    uint256 public unstakeCounter = 0;
    uint256 public taxAmount = 0;



    
    mapping(address => StakeHolder) public stakeholdersInfo;
    Epoch public currentEpoch;
    EpochStakeHolder[] public currentStakeholders;
    bool public epochInitialized = false;

    
    /// @notice Constructor to initialize the PluriStaking contract.
    /// @param _pluriToken Address of the Pluri token Proxy contract.
    constructor(address _pluriToken){
        pluriToken = IERC20PluriMethods(_pluriToken);
        lastAutoMintTimestamp = block.timestamp;
    }

    /// @notice Internal function to set the faucet address.
    /// @dev This function can only be called once and is used to initialize the faucet address. This needs to be called last after after all other inital stakers have staked.
    /// @param _faucetAddress The address of the faucet.

    function setFaucetAddress(address _faucetAddress) external onlyOwner returns (bool) {
        require(_faucetAddress != address(0), "Pluri Error: Faucet address cannot be 0");
        require(faucetAddress == address(0), "Pluri Error: Faucet already initialized");

        EpochStakeHolder memory newFaucetStakeHolder = EpochStakeHolder({
            stakerAddress: _faucetAddress,
            stakedAt: block.timestamp
        });
        currentStakeholders.push(newFaucetStakeHolder);

        StakeHolder memory newStakeHolderInfo = StakeHolder({
            stakedAt: block.timestamp,
            index: currentStakeholders.length - 1,
            earnings: 0
        });
        stakeholdersInfo[_faucetAddress] = newStakeHolderInfo;

        faucetAddress = _faucetAddress;
        emit FaucetAddressInitialized(_faucetAddress, block.timestamp);
        return true;
    }


    function updateUnstakeLimit() private {
        if (block.timestamp >= lastContainerTimestamp + 30 days) { 
            uint256 epochSize = currentEpoch.stakeholders.length;
            uint256 newLimit = epochSize * 8 / 100; // 8% of the epoch size
            currentUnstakeLimit = newLimit >= 1 ? newLimit : 1; //Mininum 1 person can unstake within 30 day period
            unstakeCounter = 0; 
            lastContainerTimestamp = block.timestamp;
        }
    }


    /// @notice Starts a new epoch, used when the current epoch is full (has 12 stakeholders).
    /// @dev Resets the currentEpoch and prepares it for a new cycle of rewards.

    function startEpoch(bool firstInitalize) private {
        currentEpoch.stakeholders = currentStakeholders;
        currentEpoch.currentIndex = 0;
        currentEpoch.epochSize = currentStakeholders.length;
        uint256 totalBalance = pluriToken.balanceOf(address(this));
        if(firstInitalize == true){
            // Balance is not updated with 11th stakeholder pluri on initalization.
            totalBalance += STAKING_AMOUNT;
        }
        uint256 totalStaked = (currentStakeholders.length - 1) * STAKING_AMOUNT;
        uint256 availableTax = 0;
        // Inlcude pluriToken.Tax to add a buffer
        if(totalBalance > (totalStaked + pluriToken.TAX())){
            uint256 taxDifference = totalBalance - totalStaked - pluriToken.TAX(); // Reserve buffer
            if(taxDifference >= pluriToken.TAX() * currentStakeholders.length){
                availableTax = taxDifference / currentStakeholders.length;
            }
        } 
        
        taxAmount = availableTax;
        emit EpochStarted(currentStakeholders.length, block.timestamp);
    }


    /// @notice Allows a user to stake their Pluri tokens.
    /// @dev Adds the staker to the currentEpoch, and if they are the 12th stakeholder, starts epoch initalization.
    /// A stakeholder must stake 21,000 PLURI for 30 days to participate in the rewards system. Will be added to next epoch.
    function stake() external returns (bool) {
        require(stakeholdersInfo[msg.sender].stakedAt == 0, "Pluri Error: Already staked");
        require(faucetAddress != address(0), "Pluri Error: Faucet address not set");
        uint256 balance = pluriToken.balanceOf(msg.sender);
        uint256 allowance = pluriToken.allowance(msg.sender, address(this));
        
        require(balance >= STAKING_AMOUNT, "Pluri Error: Insufficient PLURI balance to stake");
        require(allowance >= STAKING_AMOUNT, "Pluri Error: Contract not allowed to transfer enough PLURI tokens");
        stakeholdersInfo[msg.sender].stakedAt = block.timestamp;
         // Add the new stakeholder

        EpochStakeHolder memory newStakeholder = EpochStakeHolder({
            stakerAddress: msg.sender,
            stakedAt: block.timestamp
        });
        currentStakeholders.push(newStakeholder);

        // Swap the new stakeholder with the faucet address to ensure the faucet is always last.
        if (currentStakeholders.length > 1) {
            uint256 faucetIndex = stakeholdersInfo[faucetAddress].index;
            EpochStakeHolder memory faucet = currentStakeholders[faucetIndex];
            currentStakeholders[faucetIndex] = newStakeholder;
            currentStakeholders[currentStakeholders.length - 1] = faucet;
            stakeholdersInfo[msg.sender].index = faucetIndex;
            stakeholdersInfo[faucetAddress].index = currentStakeholders.length - 1;
        }
        
        if (!epochInitialized && currentStakeholders.length == 12) {
            startEpoch(true);
            epochInitialized = true;
            
        }
        require(pluriToken.transferFrom(msg.sender, address(this), STAKING_AMOUNT), "Pluri Error: Transfer failed");
        emit Staked(msg.sender, STAKING_AMOUNT, block.timestamp);
        return true;
    }
    
    
    /// @notice Called by the faucet to auto mint Pluri tokens and automatically distribute rewards. Self regulates based on the number of stakeholders. 
    /// @dev Manages the distribution of rewards to stakeholder and minter and resets the epoch as needed. Faucet does not recieve rewards.
    /// @param minter The address of the entity calling through the faucet.
    function autoMint(address minter) external returns (bool) {
        require(msg.sender == faucetAddress, "Pluri Error: Only faucet can execute this");
        require(epochInitialized, "Pluri Error: Epoch not initialized");
        require(block.timestamp >= lastAutoMintTimestamp + 60, "Pluri Error: Must wait at least 60 seconds between autoMint calls");
        lastAutoMintTimestamp = lastAutoMintTimestamp + 60;
        updateUnstakeLimit();

        Epoch storage epoch = currentEpoch;
        EpochStakeHolder memory recipient = epoch.stakeholders[epoch.currentIndex];
        
        // Determines the amount of Pluri to mint for the entity that utlized the faucet. 
        uint256 faucetReward = MINT_AMOUNT / epoch.epochSize;
        uint256 faucetTaxReward = taxAmount / epoch.epochSize;

        if (recipient.stakerAddress == faucetAddress) {
            // Faucet Stakeholder turn
            // Bonus of all remainders collected for mints - given to the minter only for faucet turn.
            uint256 extraReward = MINT_AMOUNT % epoch.epochSize;
            uint256 extraFaucetTaxReward = faucetTaxReward % epoch.epochSize;
            

            //Clean up the epoch and start a new epoch.
            delete currentEpoch;
            startEpoch(false);


            require(pluriToken.mint(minter, faucetReward + extraReward), "Pluri Error: Minting failed");
            require(pluriToken.transfer(minter, faucetTaxReward + extraFaucetTaxReward), "Pluri Error: Transfer failed");

            emit RewardsDistributed(minter, faucetReward + extraReward, taxAmount + extraFaucetTaxReward,  block.timestamp, RewardType.Faucet);
        } else {
            //  Stakeholder turn
            epoch.currentIndex++;

            // Update the stakeholder's earnings for informational purposes
            if(stakeholdersInfo[recipient.stakerAddress].stakedAt == recipient.stakedAt){
                stakeholdersInfo[recipient.stakerAddress].earnings += MINT_AMOUNT;
                stakeholdersInfo[recipient.stakerAddress].earnings += taxAmount;
            }

            require(pluriToken.mint(minter, faucetReward), "Pluri Error: Minting failed");
            require(pluriToken.transfer(minter, faucetTaxReward), "Pluri Error: Transfer failed");

            require(pluriToken.mint(recipient.stakerAddress, MINT_AMOUNT), "Pluri Error: Minting failed");
            require(pluriToken.transfer(recipient.stakerAddress, taxAmount), "Pluri Error: Transfer failed");

            emit RewardsDistributed(minter, faucetReward, faucetTaxReward, block.timestamp, RewardType.Faucet);
            emit RewardsDistributed(recipient.stakerAddress, MINT_AMOUNT, taxAmount, block.timestamp, RewardType.Staker);
        }
        return true;

    }

    /// @notice Allows a stakeholder to unstake their tokens after the lock-in period of 30 days. Unstaking can happen at any time if the contract is no longer a minter.
    /// @dev Manages the unstaking process and updates the stakeholder list for the next Epoch.
    function unstake() external returns (bool) {
        require(stakeholdersInfo[msg.sender].stakedAt != 0, "Pluri Error: Not a stakeholder");
        bool isActiveMinter = pluriToken.isActiveMinter(address(this));
        if(isActiveMinter) {
            require(block.timestamp >= stakeholdersInfo[msg.sender].stakedAt + LOCKIN_TIME, "Pluri Error: Cannot unstake until 30 days have passed");
            updateUnstakeLimit();
            require(unstakeCounter < currentUnstakeLimit, "Pluri Error: Unstake limit reached for the current period");
            unstakeCounter += 1;
        }
        uint256 stakerIndex = stakeholdersInfo[msg.sender].index;
        
        // Swap the last element (faucet) with the staker's address
        currentStakeholders[stakerIndex] = currentStakeholders[currentStakeholders.length - 1];

        // Pop the last element
        currentStakeholders.pop();

        // Delete the staker info
        delete stakeholdersInfo[msg.sender];

        // If the faucet is not the last item in the array, the if statement will trigger making the faucet last.
        if (stakerIndex < currentStakeholders.length - 1) {
            // Faucet is located at  currentStakeholders[stakerIndex] - swap faucet with last stakeholder now
            EpochStakeHolder memory faucet = currentStakeholders[stakerIndex];
            currentStakeholders[stakerIndex] = currentStakeholders[currentStakeholders.length - 1];
            currentStakeholders[currentStakeholders.length - 1] = faucet;

            // Update indices for faucet and the swapped address
            stakeholdersInfo[faucetAddress].index = currentStakeholders.length - 1;
            stakeholdersInfo[currentStakeholders[stakerIndex].stakerAddress].index = stakerIndex;
        }
        require(pluriToken.transfer(msg.sender, STAKING_AMOUNT), "Pluri Error: Unstaking transfer failed");
        emit Unstaked(msg.sender, STAKING_AMOUNT, block.timestamp);
        return true;

    }

    /// @notice Retrieves the address of a stakeholder at a given index in the current epoch.
    /// @param index The index of the stakeholder in the epoch.
    /// @return The address of the stakeholder at the specified index.
    function getCurrentEpochStakeholderFromIndex(uint index) external view returns (EpochStakeHolder memory) {
        Epoch storage epoch = currentEpoch;
        return epoch.stakeholders[index];
    }

     /// @notice Function to get the list of all stakeholders in the current epoch.
    /// @return An array of addresses representing all stakeholders in the current epoch.
    function getCurrentEpochStakeholders() external view returns (EpochStakeHolder[] memory) {
        return currentEpoch.stakeholders;
    }

    /// @notice Function to get the list of all current next set of stakeholders outside of the epoch.
    /// @return An array of addresses representing all current stakeholders.
    function getCurrentListOfStakeholders() external view returns (EpochStakeHolder[] memory) {
        return currentStakeholders;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
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
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
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
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
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