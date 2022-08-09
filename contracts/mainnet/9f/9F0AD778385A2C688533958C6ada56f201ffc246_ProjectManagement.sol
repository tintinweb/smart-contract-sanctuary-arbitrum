/**
 *Submitted for verification at Arbiscan on 2022-08-09
*/

// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.14;

/// @notice Sporos DAO project manager interface
interface IProjectManagement {
  /**
        @notice a DAO authorized manager can order mint of tokens to contributors within the project limits.
     */
  function mintShares(address to, uint256 amount) external payable;

  // Future versions will support tribute of work in exchange for tokens
  // function submitTribute(address fromContributor, bytes[] nftTribute, uint256 requestedRewardAmount) external payable;
  // function processTribute(address contributor, bytes[] nftTribute, uint256 rewardAmount) external payable;
}


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


abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

/**
    @notice Project management extension for KaliDAO

    DAO token holders aprove and activate Projects that authorize a specific project manager to
    issue DAO tokens to contributors in accordance with
    the terms of the project:
    - budget: A manager can order mint of DAO tokens up to a given budget.
    - deadline: A manager cannot order token mints after the project deadline expires.
    - goals: A manager is expected to act in accordance with the goals outlined in the DAO project proposal.

    A project's manager, budget, deadline and goals can be updated via DAO proposal.

    A project has exactly one manager. A manager may be assigned to 0, 1 or multiple projects.

    Modeled after KaliShareManager.sol
    https://github.com/kalidao/kali-contracts/blob/main/contracts/extensions/manager/KaliShareManager.sol

    (c) 2022 sporosdao.eth

    @author ivelin.eth

 */
contract ProjectManagement is ReentrancyGuard {
    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    event ExtensionSet(
        address indexed dao,
        Project project
    );

    event ExtensionCalled(
        address indexed dao,
        bytes[] updates
    );

    /// -----------------------------------------------------------------------
    /// Errors
    /// -----------------------------------------------------------------------

    error ProjectNotEnoughBudget();
    error ProjectExpired();
    error ProjectManagerNeedsDaoTokens();
    error ProjectUnknown();
    error ForbiddenDifferentDao();
    error ForbiddenSenderNotManager();

    /// -----------------------------------------------------------------------
    /// Project Management Storage
    /// -----------------------------------------------------------------------

    struct Project {
        uint256 id; // unique project identifier
        address dao; // the address of the DAO that this project belongs to
        address manager; // manager assigned to this project
        uint256 budget; // maximum allowed tokens the manager is authorized to mint
        uint256 deadline; // deadline date of the project
        string goals; // structured text referencing key goals for the manager's mandate
    }

    // unique project id auto-increment
    // Starts at 100 leaving 0-99 as reserved for potential future special use cases.
    // 0 is reserved for a new project proposal that has not been processed and assigned an id yet.
    uint256 public nextProjectId = 100;

    // project id -> Project mapping
    mapping(uint256 => Project) public projects;

    /// -----------------------------------------------------------------------
    /// Management Settings
    /// -----------------------------------------------------------------------

    /**

      @notice A DAO calls this method to activate an approved Project Proposal.

      @param extensionData : Contains DAO approved projects parameters; either new or existing project updates. New projects must have id of 0.

     */
    function setExtension(bytes calldata extensionData) external payable {

        // console.log("(EVM)---->: setExtension called by ", msg.sender);
        (
            uint256 id,
            address manager,
            uint256 budget,
            uint256 deadline,
            string  memory goals
        ) = abi.decode(
            extensionData,
            (uint256, address, uint256, uint256, string)
        );

        // A project maanger must be a trusted DAO token holder
        uint256 managerTokens = IERC20(msg.sender).balanceOf(manager);
        // console.log("(EVM)----> setExtension(dao, manager, managerTokens): ", msg.sender, manager, managerTokens);
        if ( managerTokens == 0) revert ProjectManagerNeedsDaoTokens();

        Project memory projectUpdate;
        projectUpdate.id = id;
        projectUpdate.manager = manager;
        projectUpdate.budget = budget;
        projectUpdate.deadline = deadline;
        projectUpdate.goals = goals;
        projectUpdate.dao = msg.sender;

        Project memory savedProject;

        if (projectUpdate.id == 0) {
            // id == 0 means new Project creation
            // assign next id and auto increment id counter
            projectUpdate.id = nextProjectId;
            // cannot realistically overflow
            unchecked {
                ++nextProjectId;
            }
        } else {
            savedProject = projects[projectUpdate.id];
            // someone is trying to update a non-existent project
            if (savedProject.id == 0) revert ProjectUnknown();
            // someone is trying to update a project that belongs to a different DAO address
            // only the DAO that created a project can modify it
            if (savedProject.dao != msg.sender) revert ForbiddenDifferentDao();
        }
        // if all safety checks passed, create/update project
        projects[projectUpdate.id] = projectUpdate;

        emit ExtensionSet(msg.sender, projectUpdate);
    }

    /// -----------------------------------------------------------------------
    /// Project Management Logic
    /// -----------------------------------------------------------------------

    /**
        @notice An authorized project manager calls this method to order a DAO token mint to contributors.

        @param dao - the dao that the project manager is authorized to manage.
        @param extensionData - contains a list of tuples: (project id, recipient contributor account, amount to mint).
     */
    function callExtension(address dao, bytes[] calldata extensionData)
        external
        payable
        nonReentrant
    {
        // console.log("(EVM)---->: callExtension called. DAO address:", dao);

        for (uint256 i; i < extensionData.length;) {
            // console.log("(EVM)----> i = ", i);
            (
                uint256 projectId,
                address toContributorAccount,
                uint256 mintAmount,
                string memory tribute
            ) = abi.decode(extensionData[i], (uint256, address, uint256, string));

            Project storage project = projects[projectId];

            // console.log("(EVM)----> projectId, toContributorAccount, mintAmount:", projectId, toContributorAccount, mintAmount);
            // console.log("(EVM)----> projectId, toContributorAccount, deliverable:", projectId, toContributorAccount, tribute);

            if (project.id == 0) revert ProjectUnknown();

            if (project.manager != msg.sender) revert ForbiddenSenderNotManager();

            if (project.deadline < block.timestamp) revert ProjectExpired();

            if (project.budget < mintAmount) revert ProjectNotEnoughBudget();

            project.budget -= mintAmount;

            // console.log("(EVM)----> updated project budget:", project.budget);

            IProjectManagement(dao).mintShares(
                toContributorAccount,
                mintAmount
            );

            // cannot realistically overflow
            unchecked {
                ++i;
            }
        }

        // console.log("(EVM)----> firing event ExtensionCalled()");

        emit ExtensionCalled(dao, extensionData);
    }
}