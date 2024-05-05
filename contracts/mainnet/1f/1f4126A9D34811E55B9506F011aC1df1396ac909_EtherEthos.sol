// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

interface iDelegate {
    function checkDelegateForContract(
        address _delegate,
        address _vault,
        address _contract,
        bytes32 rights
    ) external view returns (bool);
}

interface iExternalContract {
    function owner() external view returns (address);
}

/// @title EtherEthos (v2.0.2) - offered 'as-is', without warranty, and disclaiming liability for damages resulting from using the contract or data stored on it.
/// @author Matto AKA MonkMatto. More info: matto.xyz.
/// @notice EtherEthos is a hyperstructure that facilitates the creation of a composable EtherEthos (profile) for Ethereum addresses.
/// It empowers users to:
/// - Share links and associated accounts.
/// - Share social proofs by publicly respecting other accounts. 
/// - Write notes for other accounts (requires the recipient to respect the note writer).
/// - Store personal account details such as an alias, a description, preferred website / social media / gallery link, and a preferred NFT to use as a PFP.
/// Users should refrain from submitting Personally Identifying Information (PII) - this is the realm of crypto.
/// @notice User Responsibilities and Data Accessibility
/// - Users are responsible for the data they provide, including text descriptions, URLs, and smart contracts.
/// - By storing data in this contract, the submitted text-data becomes publicly accessible and may be used in smart contract composition.
/// - Opting-out by toggling an account's composable value to false disables most data-returning functions.
/// - However, due to the public nature of the data and immutability of the blockchain, 'opt-outs' cannot be guaranteed to be respected by third-party developers.
/// @notice Composability and Developer Responsibilities
/// - This contract encourages developers to compose with EtherEthos's data, including into tokens, in a responsible manner respecting users' 'opt-out' requests (disabled composability).
/// - Contracts aiming to compose with this contract's data must adhere to using the assemble* functions to retrieve data.
/// @dev Account Delegation and Security
/// - This contract supports account delegation, allowing authorized accounts to add or modify details on behalf of other accounts.
/// - The delegateContract variable stores the address of the Delegate contract responsible for validating delegations.
/// - The checkDelegateForContract function in the Delegate contract is called to verify if an account is authorized to act on behalf of another account.
/// - Account owners should carefully consider the implications of granting delegation permissions to other accounts.
/// @dev Moderation Features
/// - Limited moderation features are supported, allowing authorized accounts to toggle an account's composability, and to block/unblock accounts from writing to the contract.
/// - The allModerators array stores the addresses of all moderator accounts.
/// - The toggleModerator function can be called by the contract owner to grant or revoke moderator permissions.
/// @custom:experimental Warning Experimental Contract
/// - This contract is experimental, and no guarantees are made regarding its functionality, security, or lifespan.
/// - If a new version is deployed, it may not be backwards compatible.
/// - Users and developers should exercise caution when interacting with this contract and understand the potential risks involved.
/// @custom:security-contact For any security concerns, please reach out to [email protected].
/// @custom:legal-disclaimer
/// 1. Users are solely responsible for the data they provide, including text descriptions, URLs, and smart contracts. Submission of illegal, malicious, or harmful data is strictly prohibited.
/// 2. Matto, EtherEthos, Substratum, and all associated entities disclaim all liability for any damages resulting from the use or misuse of data provided by users.
/// 3. EtherEthos does not have control over user-submitted content, nor provides any guarantee on the safety or reliability of any data, including links to third-party websites or contracts.
/// 4. The use of any data, links, or contracts stored within this contract and presented by frontend applications is entirely at the end-user's risk.
/// 5. The act of composing data from this contract into tokens, other contracts, or digital assets lies solely at the discretion and risk of the user and/or contract developer.
/// 6. Such composability carries risks and implications, which may include but are not limited to data permanence, security issues, social costs, and legal considerations. By accessing this contract, users and developers, certify they have considered the potential risks and accept all risks and implications both foreseeable and unforeseeable at the time of use.
/// @notice Legal Variable
/// - If present, the data stored in this contract's 'legal' variable supersedes the above legal disclaimers.
/// - In the event of conflicting terms, the conditions outlined in the 'legal' variable take precedence.

contract EtherEthos is Ownable {
    using Strings for string;

    // Contains the permissions for each account.
    struct Perms {
        bool composable; // Whether or not the account has an active composable EtherEthos.
        bool accountIsBlocked; // Whether or not the account is blocked.
        bool moderator; // Whether or not the account is a moderator.
        string verificationResponse; // The response to a verification request.
    }

    // Contains basic account information. The 'Detail' string is limited to 320 bytes, while all other strings are limited to 160 bytes.
    struct Basics {
        string accountAlias; // An alias or nickname for the account.
        string detail; // Detailed information about the account.
        string socialLink; // Social media link for the account.
        string website; // Website link for the account.
        string gallery; // Link to a gallery of the account's work or collection.
        uint256 ping; // A timestamp of the last time the account was pinged.
        uint256 pfpTokenId; // The token ID of the profile picture NFT.
        address pfpContract; // The contract address of the profile picture NFT.
        uint8 priorityLink; // stores the priority link for the account.
    }

    // Pairs two strings together for various uses in the contract. k and v are used to represent the key and value type of relationship of the pair.
    struct StrPair {
        string k; // The first string in the pair.
        string v; // The second string associated with the first string.
    }

    // Pairs an address with a string for various uses in the contract. k and v are used to represent the key and value type of relationship of the pair.
    struct AddrPair {
        address k; // The address in the pair.
        string v; // The string associated with the address.
    }

    // The legal disclaimer override for the contract.
    string public legal;
    // The number of active Composable EtherEthos records (EEs) in the contract.
    uint256 public activeEEs;
    // Stores all moderators in a public array.
    address[] public allModerators;
    // Stores the permissions for each account.
    mapping(address => Perms) public permissions;
    // Stores the maximum number of notes allowed per account. This is updatable.
    uint256 private maxNotesPerAccount = 128;

    // The address of the Delegate contract. This is updatable.
    address private delegateContract = 0x00000000000000447e69651d841bD8D104Bed493;

    // Stores the basic information for each account.
    mapping(address => Basics) private basics;
    // Stores a string of any size for use in specific composability scenarios.
    mapping(address => string) private custom;

    // Stores an array of additional link pairs (URL and description) for each account.
    mapping(address => StrPair[]) private additionalLinks;
    // Stores an array of associated account pairs (address and description) for each account.
    mapping(address => AddrPair[]) private associatedAccounts;
    // Stores an array notesReceived pairs (note text and writing account) for each account.
    mapping(address => AddrPair[]) private notesReceived;
    // Stores an array notesReceived pairs (note text and writing account) for each account.
    mapping(address => address[]) private notesSent;

    // Keeps track of the index of each note writer's address in the note recipient's array of noteWriters.
    mapping(address => mapping(address => uint256)) private noteWritersIndex;
    // Keeps track of where each note recipient's address is in the note writer's array of noteRecipients.
    mapping(address => mapping(address => uint256)) private notesSentIndex;
    // Stores an array of tags for each account.
    mapping(address => string[]) private tags;

    // Stores the addresses of accounts who have respected each account.
    mapping(address => address[]) private respecters;
    // Keeps track of where each respecter's address is in the respected account's array of respecters.
    mapping(address => mapping(address => uint256)) private respectersIndex;
    // Stores the addresses of accounts that each account respects.
    mapping(address => address[]) private respecting;
    // Keeps track of where each respected address is in the respecting account's array.
    mapping(address => mapping(address => uint256)) private respectingIndex;

    /// @notice Event to alert clients that a EtherEthos's composability has been changed for an account.
    /// @dev This event is emitted when a user adds basic data to their EtherEthos or toggles their EtherEthos's composability state.
    /// This provides a way to track account composability on-chain.
    /// @param _account The address of the account whose EtherEthos composability has changed.
    /// @param _status The new composability status of the account. True indicates that the account's EtherEthos is now composable, false indicates that the account's EtherEthos is no longer composable.
    event Composable(address indexed _account, bool _status);

    /// @notice Event to alert clients that an account has become or stopped being a moderator.
    /// @dev Emitted when the moderator status of an account is toggled.
    /// @param _account The address of the account whose moderator status has been changed.
    /// @param _status The new moderator status of the account. True indicates that the account is a moderator,
    /// false indicates that the account is not a moderator.
    event Moderator(address indexed _account, bool _status);

    /// @notice Event to alert clients that an account has been blocked or unblocked.
    /// @dev Emitted when an account's access to write data to the contract is toggled.
    /// @param _account The address of the account whose access status has been changed.
    /// @param _status The new access status of the account. True indicates that the account is now blocked from writing to the contract, false indicates that the account is unblocked.
    event Blocked(address indexed _account, bool _status);

    /// @notice Event to alert clients that an account has been respected / unrespected.
    /// @dev Emitted when an account has a change in respect status.
    /// @param _respected The address of the account that has been respected.
    /// @param _respecter The address of the account that has respected the other account.
    /// @param _status The new respect status of the account.
    event Respected(
        address indexed _respected,
        address indexed _respecter,
        bool _status
    );

    /// @notice Event to alert clients that an account recieved a note.
    /// @dev Emitted when an account has a note written for them, or when a note is updated.
    /// @param _noteReceiver The address of the account that has recieved a note.
    /// @param _noteWriter The address of the account that has written the note.
    /// @param _note The note that has been written.
    event Noted(
        address indexed _noteReceiver,
        address indexed _noteWriter,
        string _note
    );

    /// @notice Event to alert clients that the contract has updated terms stored in the legal variable.
    /// @dev Emitted when the content in the legal variable is updated.
    /// @param _legal The new content to be stored in the legal variable.
    event LegalUpdated(string _legal);

    /// @notice Checks if the sender is authorized to act on behalf of a specified account.
    /// @dev The sender must either be the account itself or a valid delegate.
    /// The account must not be blocked. The delegate validity is checked via a separate contract.
    /// @param _account The account for which the sender might be acting.
    modifier isAuthorized(address _account) {
        require(_accountAuthorized(_account), "!Au");
        _;
    }

    /// @notice Checks if the given requester is authorized for the given account.
    /// @dev The requester is considered authorized if they are the account itself or a valid delegate.
    /// The delegate validity is checked via a separate contract.
    /// @param _account The account to be checked for authorization.
    /// @return Returns true if the requester is authorized for the given account, otherwise false.
    function _accountAuthorized(address _account) internal view returns (bool) {
        require(!permissions[_account].accountIsBlocked, "Blocked");
        address requester = msg.sender;
        return
            requester == _account ||
            iDelegate(delegateContract).checkDelegateForContract(
                requester,
                _account,
                address(this),
                ""
            ) ||
            requester == iExternalContract(_account).owner();
    }

    /// @notice Checks if the account has a composable EtherEthos.
    /// @dev simplifies external calls for checking if an account has a composable EtherEthos.
    /// @param _account The account to check.
    /// @return A boolean indicating whether or not the account has a composable EtherEthos.
    function isComposable(address _account) external view returns (bool) {
        return permissions[_account].composable;
    }

    /// @notice This function is used to update the timestamp of the last time an account was pinged.
    /// @dev This contract can be deployed on any Ethereum L2, and keeping data across L1 and L2s in sync is a challenge.
    /// This function is used to update the timestamp of the last time an account was pinged, which can be compared across layers.
    /// @param _account The account whose ping timestamp is being updated.
    function ping(address _account) public isAuthorized(_account) {
        basics[_account].ping = block.timestamp;
    }

    /// @notice Updates the verification response for a given account.
    /// @dev This function is updates a publicly viewable string that is intended to be used as a verification response.
    /// This field is cannot be disabled by setting composable to false.
    /// Calling account must be authorized to act on behalf of the account being updated.
    /// @param _account The account whose verification response is being updated.
    /// @param _verificationResponse The new verification response for the account.
    function setVerificationResponse(
        address _account,
        string calldata _verificationResponse
    ) external isAuthorized(_account) {
        permissions[_account].verificationResponse = _verificationResponse;
    }

    /// @notice Retrieves all additional links associated with the provided account.
    /// @dev This function returns an array of StrPair structures, which contain the URL or identifier of the link and a brief description or detail about the link.
    /// @param _account The account whose additional links are being queried.
    /// @return A dynamic array of StrPair structures (tuples) representing all the additional links associated with the queried account and their associated details.
    function getAdditionalLinkTuples(
        address _account
    ) external view returns (StrPair[] memory) {
        require(permissions[_account].composable);
        return additionalLinks[_account];
    }

    /// @notice Retrieves all associated accounts associated with the provided account.
    /// @dev This function returns an array of AddrPair structures, which contain the address of an associated account and a brief description or detail about that account.
    /// @param _account The account whose associated accounts are being queried.
    /// @return A dynamic array of AddrPair structures (tuples) representing all of an account's associated accounts and their details.
    function getAssociatedAccountTuples(
        address _account
    ) external view returns (AddrPair[] memory) {
        require(permissions[_account].composable);
        return associatedAccounts[_account];
    }

    /// @notice Allows owner to change the maximum number of notes allowed per user.
    /// @dev This function can only be called by the contract owner.
    /// @param _maxNotesPerAccount The new maximum number of notes allowed per user.
    function updateMaxNotesPerAccount(uint256 _maxNotesPerAccount) external onlyOwner {
        maxNotesPerAccount = _maxNotesPerAccount;
    }

    /// @notice Updates the legal disclaimer for the contract.
    /// @dev This function can only be called by the contract owner.
    /// @param _legal The new legal disclaimer.
    function updateLegal(string calldata _legal) external onlyOwner {
        legal = _legal;
        emit LegalUpdated(_legal);
    }

    /// @notice Updates the Delegate contract address.
    /// @dev This function can only be called by the contract owner.
    /// @param _delegateContract The new Delegate contract address.
    function updateDelegateContract(address _delegateContract) external onlyOwner {
        delegateContract = _delegateContract;
    }

    /// @notice Toggles the moderator status of an account.
    /// @dev Moderators have permissions to block/unblock accounts and set records.
    /// Toggling changes the account's moderator status; if the account was a moderator,
    /// it will no longer be one, and vice versa.
    /// The account's address is also added to or removed from the allModerators array.
    /// This function can only be called by the contract owner.
    /// @param _account The account whose moderator status is being changed.
    function toggleModerator(address _account) external onlyOwner {
        if (permissions[_account].moderator) {
            for (uint256 i = 0; i < allModerators.length; i++) {
                if (allModerators[i] == _account) {
                    allModerators[i] = allModerators[allModerators.length - 1];
                    allModerators.pop();
                    break;
                }
            }
        } else {
            allModerators.push(_account);
        }
        permissions[_account].moderator = !permissions[_account].moderator;
        emit Moderator(_account, permissions[_account].moderator);
    }

    /// @notice Toggles an account's access to write data to the contract.
    /// @dev A moderator has the permission to block/unblock accounts from writing to the contract.
    /// This function changes the access status of an account: if it was blocked, it will be unblocked and vice versa.
    /// Note that a moderator cannot block/unblock their own account.
    /// @param _account The account whose access status is being changed.
    function toggleAccountBlock(address _account) external {
        require(permissions[msg.sender].moderator && msg.sender != _account);
        if (!permissions[_account].accountIsBlocked) {
            permissions[_account].accountIsBlocked = true;
            _deactivateComposability(_account);
        } else {
            permissions[_account].accountIsBlocked = false;
        }
        emit Blocked(_account, permissions[_account].accountIsBlocked);
    }

    /// @notice Used by an account to block itself due to a compromised private key.
    /// @dev This function blocks and deactivates composability for the account.
    /// @param _account The account that is blocking itself.
    function blockMyCompromisedAccount(address _account) external isAuthorized(_account) {
        permissions[_account].accountIsBlocked = true;
        _deactivateComposability(_account);
        emit Blocked(_account, true);
    }

    /// @notice Allows setting many of the basic details of an account at once.
    /// @dev By setting many basic details at once, it can help save gas costs and also activates the EtherEthos.
    /// The detail is limited to 320 bytes, while all other strings are limited to 160 bytes.
    /// If a string is longer than allowed, the transaction will fail, costing gas.
    /// This operation can only be performed by an authorized entity.
    /// @param _account The account whose details are being updated.
    /// @param _alias The new alias to be associated with the account. This could be a nickname or a pseudonym.
    /// @param _detail The new detail text to be stored. This could include additional information about the account holder.
    /// @param _socialLink A new socialLink text to be stored. This could be a link to a social media.
    /// @param _website A new website link text to be stored.
    /// @param _gallery A new gallery link text to be stored.
    function setMainBasics(
        address _account,
        string calldata _alias,
        string calldata _detail,
        string calldata _socialLink,
        string calldata _website,
        string calldata _gallery
    ) external isAuthorized(_account) {
        _checkStringLength(_alias, 160, 0);
        _checkStringLength(_socialLink, 160, 2);
        _checkStringLength(_website, 160, 3);
        _checkStringLength(_gallery, 160, 4);
        _checkStringLength(_detail, 320, 1);

        Basics storage userBasics = basics[_account];
        userBasics.accountAlias = _alias;
        userBasics.detail = _detail;
        userBasics.socialLink = _socialLink;
        userBasics.website = _website;
        userBasics.gallery = _gallery;
        _activateComposability(_account);
        ping(_account);
    }

    /// @notice Sets an alias or username for a given account.
    /// @dev Setting an alias not only helps identify the account but also activates the EtherEthos's composability if it's not already active.
    /// Activating the EtherEthos will allow data to be returned from the contract.
    /// Only an authorized user can set the alias.
    /// @param _account The account for which the alias is being set.
    /// @param _alias The new alias to be associated with the account. This could be a nickname or a pseudonym.
    function setAlias(
        address _account,
        string calldata _alias
    ) external isAuthorized(_account) {
        _checkStringLength(_alias, 160, 0);
        basics[_account].accountAlias = _alias;
        _activateComposability(_account);
    }

    /// @notice Assigns a new detail or description to a specified account.
    /// @dev Assigning a detail not only helps provide more context about the account,
    /// but also activates the EtherEthos's composability if it's not already active,
    /// which will allow data to be returned from the contract.
    /// @param _account The account for which the detail is being set.
    /// @param _detail The new detail or description to be associated with the account.
    /// This could provide some context about the account or its owner.
    function setDetail(
        address _account,
        string calldata _detail
    ) external isAuthorized(_account) {
        _checkStringLength(_detail, 320, 1);
        basics[_account].detail = _detail;
        _activateComposability(_account);
    }

    /// @notice Assigns a new socialLink to a specified account.
    /// @dev Assigning a socialLink not only serves as a publicly listed social media link,
    /// but it also activates the EtherEthos's composability if it's not already active,
    /// which allows data to be returned from the contract.
    /// @param _account The account for which the socialLink is being set.
    /// @param _socialLink A new socialLink text to be stored. This could be a social media page.
    function setSocial(
        address _account,
        string calldata _socialLink
    ) external isAuthorized(_account) {
        _checkStringLength(_socialLink, 160, 2);
        basics[_account].socialLink = _socialLink;
        _activateComposability(_account);
    }

    /// @notice Assigns a new website link to a specified account.
    /// @dev Assigning a website link not only serves as a publicly listed website link,
    /// but it also activates the EtherEthos's composability if it's not already active,
    /// which allows data to be returned from the contract.
    /// @param _account The account for which the website link is being set.
    /// @param _website A new website link text to be stored.
    function setWebsite(
        address _account,
        string calldata _website
    ) external isAuthorized(_account) {
        _checkStringLength(_website, 160, 3);
        basics[_account].website = _website;
        _activateComposability(_account);
    }

    /// @notice Assigns a new gallery link to a specified account.
    /// @dev Assigning a gallery link not only serves as a publicly listed gallery link,
    /// but it also activates the EtherEthos's composability if it's not already active,
    /// which allows data to be returned from the contract.
    /// @param _account The account for which the gallery link is being set.
    /// @param _gallery A new gallery link text to be stored.
    function setGallery(
        address _account,
        string calldata _gallery
    ) external isAuthorized(_account) {
        _checkStringLength(_gallery, 160, 4);
        basics[_account].gallery = _gallery;
        _activateComposability(_account);
    }

    /// @notice Assigns a new priority link to a specified account.
    /// @dev The priority link is used to request which link a third-party application would most prominantly display.
    /// The priority link has a default value of 0, meaning the social media link is prioritized.
    /// Use 1 to prioritize the website link, and 2 to prioritize the gallery link.
    /// @param _account The account for which the priority link is being set.
    /// @param _priorityLink A new priority link uint8 value to be stored.
    function setPriorityLink(
        address _account,
        uint8 _priorityLink
    ) external isAuthorized(_account) {
        basics[_account].priorityLink = _priorityLink;
    }

    /// @notice Assigns a preferred NFT (Non-Fungible Token) Profile Picture (PFP) to a specific account.
    /// @dev Assigning an NFT as a PFP doesn't activate the EtherEthos's composability if it's not already active.
    /// This function is used to specify the contract and the token ID of the NFT the account prefers as its PFP.
    /// Please note that PFP ownership is not validated in this contract,
    /// and ownership might need to be validated when the data is being composed live in third party applications.
    /// @param _account The account for which the PFP is being set.
    /// @param _pfpContract The address of the smart contract that controls the NFT to be used as a PFP.
    /// @param _pfpTokenId The unique identifier (token ID) of the NFT to be used as a PFP.
    function setPFP(
        address _account,
        address _pfpContract,
        uint256 _pfpTokenId
    ) external isAuthorized(_account) {
        basics[_account].pfpContract = _pfpContract;
        basics[_account].pfpTokenId = _pfpTokenId;
    }

    /// @notice Sets a custom string for a given account.
    /// @dev The custom field is provided for flexibility in collective composability.
    /// Eg. a DAO wants something composable specific to them -
    /// they could ask their members to each set data in this field appropriately formatted for their use case.
    /// This string is not limited to 160 bytes, and it is not included in standard return functions, but is still publicly accessible.
    /// Only an authorized user can set the custom data.
    /// @param _account The account for which the custom data is being set.
    /// @param _custom The new custom data to be associated with the account. This could be anything.
    function setCustomData(
        address _account,
        string calldata _custom
    ) external isAuthorized(_account) {
        custom[_account] = _custom;
    }

    /// @notice Adds a new link and its description to an account's list of additional links.
    /// @dev This function creates a new StrPair object with the given link and its description,
    /// and then adds this pair to the account's list of additional links. Only authorized users can add links.
    /// @param _account The account for which the additional link is being added.
    /// @param _link The actual URL or identifier of the additional link being added.
    /// @param _detail A brief description or detail about the additional link being added.
    function pushAdditionalLink(
        address _account,
        string calldata _link,
        string calldata _detail
    ) external isAuthorized(_account) {
        _checkStringLength(_link, 160, 5);
        _checkStringLength(_detail, 160, 1);
        StrPair memory newLink = StrPair(_link, _detail);
        additionalLinks[_account].push(newLink);
    }

    /// @notice Allows editing of an existing link and its corresponding description in an account's list of additional links.
    /// @dev This function modifies an existing StrPair object in the account's list of additional links,
    /// based on the provided index. Only authorized users can edit links.
    /// The correct index can be determined by using the public getAdditionalLinkTuples() function.
    /// @param _account The account for which the additonal link is being edited.
    /// @param _index The position in the list of additional links where the link to be edited is located.
    /// @param _link The updated URL or identifier of the additional link.
    /// @param _detail The updated description or detail about the additional link.
    function updateAdditionalLink(
        address _account,
        uint256 _index,
        string calldata _link,
        string calldata _detail
    ) external isAuthorized(_account) {
        require(_index < additionalLinks[_account].length);
        _checkStringLength(_link, 160, 5);
        _checkStringLength(_detail, 160, 1);
        additionalLinks[_account][_index].k = _link;
        additionalLinks[_account][_index].v = _detail;
    }

    /// @notice Allows removal of a link and its corresponding description from an account's list of additional links.
    /// @dev This function removes a specified StrPair object from the account's list of additional links.
    /// The specified link is replaced with the last link in the list and the last link is then removed.
    /// The index can be obtained through the corresponding public getAdditionalLinkTuples() function.
    /// @param _account The account for which the additional link is being removed.
    /// @param _index The position in the list of additional links of the link to be removed.
    function deleteAdditionalLink(
        address _account,
        uint256 _index
    ) external isAuthorized(_account) {
        require(_index < additionalLinks[_account].length);
        additionalLinks[_account][_index] = additionalLinks[_account][
            additionalLinks[_account].length - 1
        ];
        additionalLinks[_account].pop();
    }

    /// @notice Adds a new tag to an account's list of tags.
    /// @dev Individual tags are limited to 32 bytes.
    /// @param _account The account for which the tag is being added.
    /// @param _tag The tag being added. It should not include the '#' symbol.
    function pushTag(
        address _account,
        string calldata _tag
    ) external isAuthorized(_account) {
        _checkStringLength(_tag, 32, 6);
        tags[_account].push(_tag);
    }

    /// @notice Allows removal of a tag from an account's list of additional tags.
    /// @dev This function removes a specified tag from the account's list of tags.
    /// The specified tag is replaced with the last tag in the list and the last tag is then removed.
    /// The index can be obtained through the corresponding public assembleTags() function.
    /// @param _account The account for which the tag is being removed.
    /// @param _index The position in the list of tags of the tag to be removed.
    function deleteTag(
        address _account,
        uint256 _index
    ) external isAuthorized(_account) {
        require(_index < tags[_account].length);
        tags[_account][_index] = tags[_account][tags[_account].length - 1];
        tags[_account].pop();
    }

    /// @notice Adds an associated account and description to an account's list of associated accounts.
    /// @dev The caller must be authorized to access the _account.
    /// The _associatedAccount and its _detail will be stored as an associated account of the _account.
    /// @param _account The account to which an associated account is to be stored.
    /// @param _associatedAccount The associated account to be stored with _account.
    /// @param _detail A description or detail associated with the _associatedAccount.
    function pushAssociatedAccount(
        address _account,
        address _associatedAccount,
        string calldata _detail
    ) external isAuthorized(_account) {
        _checkStringLength(_detail, 160, 1);
        AddrPair memory newAssociatedAccount = AddrPair(
            _associatedAccount,
            _detail
        );
        associatedAccounts[_account].push(newAssociatedAccount);
    }

    /// @notice Modifies the associated account and description in the account's list of associated accounts.
    /// @dev The caller must be authorized to access the _account.
    /// The _associatedAccount and _detail replace the associated account and description at _index in the _account's associated accounts.
    /// The index can be obtained through the corresponding public getAssociatedAccountTuples() function.
    /// @param _account The account for which an associated account is being modified.
    /// @param _index The index in the list of associated accounts where modifications are to be made.
    /// @param _associatedAccount The new associated account to replace the current associated account at the _index position.
    /// @param _detail The new description to replace the current description at the _index position.
    function updateAssociatedAccount(
        address _account,
        uint256 _index,
        address _associatedAccount,
        string calldata _detail
    ) external isAuthorized(_account) {
        require(_index < associatedAccounts[_account].length);
        _checkStringLength(_detail, 160, 1);
        associatedAccounts[_account][_index].k = _associatedAccount;
        associatedAccounts[_account][_index].v = _detail;
    }

    /// @notice Removes an associated account and its description from the account's list of associated accounts.
    /// @dev The caller must be authorized to access the _account.
    /// The _index should point to the associated account and description to be removed in the _account's associated account list.
    /// The index can be obtained through the corresponding public getAssociatedAccountTuples() function.
    /// This function removes the associated account and description by swapping them with the last associated account and description in the list,
    /// and then reducing the list's length by one.
    /// @param _account The account from which an associated account and description is being removed.
    /// @param _index The index in the list of associated accounts where the associated account and description are to be removed.
    function deleteAssociatedAccount(
        address _account,
        uint256 _index
    ) external isAuthorized(_account) {
        require(_index < associatedAccounts[_account].length);
        associatedAccounts[_account][_index] = associatedAccounts[_account][
            associatedAccounts[_account].length - 1
        ];
        associatedAccounts[_account].pop();
    }

    /// @notice Allows an account to respect another account. This allows the respected account to write a note for the respecter.
    /// @dev The respecter's address is added to the respected account's array of respecters.
    /// The index of this new respectater in the array is also stored.
    /// @param _respectGiver The account that is respecting another account.
    /// @param _respectReceiver The account that is being respected by _respectGiver.
    function giveRespect(
        address _respectGiver,
        address _respectReceiver
    ) external isAuthorized(_respectGiver) {
        require(_respectGiver != _respectReceiver);
        require(
            respectersIndex[_respectReceiver][_respectGiver] == 0 &&
                (respecters[_respectReceiver].length == 0 ||
                    respecters[_respectReceiver][0] != _respectGiver),
            "Respecting"
        );

        // Add to respecters array
        respecters[_respectReceiver].push(_respectGiver);
        respectersIndex[_respectReceiver][_respectGiver] =
            respecters[_respectReceiver].length -
            1;

        // Add to respecting array
        respecting[_respectGiver].push(_respectReceiver);
        respectingIndex[_respectGiver][_respectReceiver] =
            respecting[_respectGiver].length -
            1;

        emit Respected(_respectReceiver, _respectGiver, true);
    }

    /// @notice Allows an account to revoke respect that it has made for another account.
    /// @dev The respecter's address is removed from the respected account's array of respecters.
    /// The element at the end of the array is moved to the deleted element's slot to avoid leaving a gap.
    /// The respectersIndex mapping is updated to reflect these changes.
    /// @param _respectRevoker The account that is revoking its respect for another account.
    /// @param _losingRespect The account for which the _respectRevoker's respect is being revoked.
    function revokeRespect(
        address _respectRevoker,
        address _losingRespect
    ) external isAuthorized(_respectRevoker) {
        // Logic for respecters array
        uint index = respectersIndex[_losingRespect][_respectRevoker];
        address[] storage respectedBy = respecters[_losingRespect];
        respectedBy[index] = respectedBy[respectedBy.length - 1];
        respectersIndex[_losingRespect][respectedBy[index]] = index;
        respectedBy.pop();
        delete respectersIndex[_losingRespect][_respectRevoker];

        // Logic for respecting array
        uint indexOfRespecting = respectingIndex[_respectRevoker][
            _losingRespect
        ];
        address[] storage respectsTo = respecting[_respectRevoker];
        respectsTo[indexOfRespecting] = respectsTo[respectsTo.length - 1];
        respectingIndex[_respectRevoker][
            respectsTo[indexOfRespecting]
        ] = indexOfRespecting;
        respectsTo.pop();
        delete respectingIndex[_respectRevoker][_losingRespect];

        emit Respected(_losingRespect, _respectRevoker, false);
    }

    /// @notice Allows an account to write a note for another.
    /// @dev The note will only be shown if the note recipient respects the note writer.
    /// @param _noteWriter The account that is writing a note for another.
    /// @param _noteReceiver The account that is receiving a note.
    /// @param _note The note being written by the _noteWriter for the _noteReceiver.
    function setNote(
        address _noteWriter,
        address _noteReceiver,
        string calldata _note
    ) external isAuthorized(_noteWriter) {
        require(_noteWriter != _noteReceiver, "!self");
        require(
            respectersIndex[_noteWriter][_noteReceiver] != 0 ||
            respecters[_noteWriter][0] == _noteReceiver,
            "!Au"
        );
        _checkStringLength(_note, 160, 7);

        // Cache frequently accessed data in memory variables
        AddrPair[] storage receivedNotes = notesReceived[_noteReceiver];
        mapping(address => uint256) storage writersIndex = noteWritersIndex[_noteReceiver];
        address[] storage sentNotes = notesSent[_noteWriter];
        mapping(address => uint256) storage sentIndex = notesSentIndex[_noteWriter];

        // Check if the note receiver has reached the maximum number of notes
        require(receivedNotes.length < maxNotesPerAccount, "R.lim");

        // Check if the note sender has reached the maximum number of notes
        require(sentNotes.length < maxNotesPerAccount, "S.lim");

        // Handle the case where the receiving account has no notes
        if (receivedNotes.length == 0) {
            writersIndex[_noteWriter] = 0;
            receivedNotes.push(AddrPair(_noteWriter, _note));
        }
        // Handle the case where the receiving account has a note from the writer
        else if (writersIndex[_noteWriter] > 0) {
            receivedNotes[writersIndex[_noteWriter]].v = _note;
        }
        // Handle the case where the receiving account has no note from the writer
        else {
            writersIndex[_noteWriter] = receivedNotes.length;
            receivedNotes.push(AddrPair(_noteWriter, _note));
        }

        // Handle the case where the _noteReceiver is not yet in the _noteWriter's sent notes list
        if (sentIndex[_noteReceiver] == 0) {
            sentNotes.push(_noteReceiver);
            sentIndex[_noteReceiver] = sentNotes.length - 1;
        }

        emit Noted(_noteReceiver, _noteWriter, _note);
    }

    /// @notice Allows an account to remove a note it has received from another account.
    /// The specified note is replaced with the last note in the list and the last note is then removed.
    /// The index can be obtained through the corresponding public getNoteTuples() function.
    /// @param _account The account that is removing a note it has received.
    /// @param _noteAuthor The account that wrote the note.
    function deleteReceivedNote(
        address _account,
        address _noteAuthor
    ) external isAuthorized(_account) {
        uint256 index = noteWritersIndex[_account][_noteAuthor];
        require(notesReceived[_account][index].k == _noteAuthor, "!Exist");

        // Cache frequently accessed data in memory variables
        AddrPair[] storage receivedNotes = notesReceived[_account];
        mapping(address => uint256) storage writersIndex = noteWritersIndex[_account];
        address[] storage sentNotes = notesSent[_noteAuthor];
        mapping(address => uint256) storage sentIndex = notesSentIndex[_noteAuthor];

        // Remove the note from notesReceived
        uint256 lastIndex = receivedNotes.length - 1;
        if (index != lastIndex) {
            AddrPair memory lastNote = receivedNotes[lastIndex];
            receivedNotes[index] = lastNote;
            writersIndex[lastNote.k] = index;
        }
        receivedNotes.pop();
        delete writersIndex[_noteAuthor];

        // Remove _account from _noteAuthor's notesSent array
        uint256 sentIndexToRemove = sentIndex[_account];
        lastIndex = sentNotes.length - 1;
        if (sentIndexToRemove != lastIndex) {
            address lastRecipient = sentNotes[lastIndex];
            sentNotes[sentIndexToRemove] = lastRecipient;
            sentIndex[lastRecipient] = sentIndexToRemove;
        }
        sentNotes.pop();
        delete sentIndex[_account];

        emit Noted(_account, _noteAuthor, "Deleted by receiver");
    }

    /// @notice Allows an account to remove a note it has written for another account.
    /// @dev The recipient is removed from the sender's notesSent array by overwriting it with the last recipient and then popping the last entry.
    /// @param _account The account that is removing a note they wrote for another.
    /// @param _accountLosingNote The account that is having a note removed.
    function deleteWrittenNote(
        address _account,
        address _accountLosingNote
    ) external isAuthorized(_account) {
        uint256 indexToRemove = noteWritersIndex[_accountLosingNote][_account];
        require(indexToRemove > 0 || notesReceived[_accountLosingNote][0].k == _account, "!Exist");

        // Cache frequently accessed data in memory variables
        AddrPair[] storage receivedNotes = notesReceived[_accountLosingNote];
        mapping(address => uint256) storage writersIndex = noteWritersIndex[_accountLosingNote];
        address[] storage sentNotes = notesSent[_account];
        mapping(address => uint256) storage sentIndex = notesSentIndex[_account];

        // Remove the note from notesReceived
        uint256 lastIndex = receivedNotes.length - 1;
        if (indexToRemove != lastIndex) {
            AddrPair memory lastNote = receivedNotes[lastIndex];
            receivedNotes[indexToRemove] = lastNote;
            writersIndex[lastNote.k] = indexToRemove;
        }
        receivedNotes.pop();
        delete writersIndex[_account];

        // Remove _accountLosingNote from _account's notesSent array
        uint256 sentIndexToRemove = sentIndex[_accountLosingNote];
        lastIndex = sentNotes.length - 1;
        if (sentIndexToRemove != lastIndex) {
            address lastRecipient = sentNotes[lastIndex];
            sentNotes[sentIndexToRemove] = lastRecipient;
            sentIndex[lastRecipient] = sentIndexToRemove;
        }
        sentNotes.pop();
        delete sentIndex[_accountLosingNote];

        emit Noted(_accountLosingNote, _account, "Deleted by writer");
    }

    /// @notice Allows a user to reconcile any inconsistencies in their note data.
    /// @dev This function reconciles both sent and received notes for the user.
    /// It iterates through the user's sent notes and checks if each recipient still has the corresponding note.
    /// If a recipient no longer has the note, it is removed from the user's sent notes array.
    /// It also iterates through the user's received notes and checks if the note writer still has the user as a recipient.
    /// If the note writer no longer has the user as a recipient, the note is removed from the user's received notes array.
    /// @param _account The account to reconcile note data for.
    function reconcileNotes(address _account) external isAuthorized(_account) {

        // Cache frequently accessed data in memory variables
        address[] storage sentNotes = notesSent[_account];
        mapping(address => uint256) storage sentIndex = notesSentIndex[_account];
        AddrPair[] storage receivedNotes = notesReceived[_account];
        mapping(address => uint256) storage writersIndex = noteWritersIndex[_account];

        // Reconcile sent notes
        for (uint256 i = 0; i < sentNotes.length; i++) {
            address recipient = sentNotes[i];
            uint256 noteIndex = noteWritersIndex[recipient][_account];

            // Check if the recipient still has the note
            if (noteIndex >= notesReceived[recipient].length || notesReceived[recipient][noteIndex].k != _account) {
                // If the recipient doesn't have the note, remove it from the user's sent notes array
                uint256 lastIndex = sentNotes.length - 1;
                if (i != lastIndex) {
                    address lastRecipient = sentNotes[lastIndex];
                    sentNotes[i] = lastRecipient;
                    sentIndex[lastRecipient] = i;
                }
                sentNotes.pop();
                delete sentIndex[recipient];
                i--; // Adjust the index to account for the removed note
            }
        }

        // Reconcile received notes
        for (uint256 i = 0; i < receivedNotes.length; i++) {
            address writer = receivedNotes[i].k;
            uint256 noteIndex = sentIndex[_account];

            // Check if the note writer still has the user as a recipient
            if (noteIndex >= notesSent[writer].length || notesSent[writer][noteIndex] != _account) {
                // If the note writer doesn't have the user as a recipient, remove the note from the user's received notes array
                uint256 lastIndex = receivedNotes.length - 1;
                if (i != lastIndex) {
                    AddrPair memory lastNote = receivedNotes[lastIndex];
                    receivedNotes[i] = lastNote;
                    writersIndex[lastNote.k] = i;
                }
                receivedNotes.pop();
                delete writersIndex[writer];
                i--; // Adjust the index to account for the removed note
            }
        }
    }


    /// @notice Toggles the visibility state of an account's EtherEthos - the collected reporting of all account data.
    /// @dev If the EtherEthos's composability is active, this function deactivates it, and vice versa.
    /// This function can be called by authorized accounts and by moderators.
    /// An account's composable status can be obtained from the public getter function for an account's permissions.
    /// @param _account The account for which to toggle the composable state.
    function toggleComposable(
        address _account
    ) external {
        require(
            _accountAuthorized(_account) || permissions[msg.sender].moderator,
            "!Au"
        );
        if (!permissions[_account].composable) {
            _activateComposability(_account);
        } else {
            _deactivateComposability(_account);
        }
    }

    /// @notice Returns almost all account data for a given account if it is not blocked and the EtherEthos composability is active.
    /// @dev Subfunctions are called to build respective data arrays.
    /// These subfunctions are also external and can be called individually.
    /// @param _account The account whose data is to be retrieved.
    /// @return accountData A 2D string array containing various account data.
    ///     Indices structure:
    ///     [0]: Basic Data - Includes account alias, detail, socialLink, link priority, PFP contract and Token ID.
    ///     [1]: Additional Links - Includes all the additional links associated with the account.
    ///     [2]: Associated Accounts - List of an account's Associated Accounts.
    ///     [3]: respecters - List of accounts that have respected the account.
    ///     [4]: respecting - List of accounts that the account has respected.
    ///     [5]: notes received - List of notes that have been written for the account.
    ///     [6]: notes sent - List of notes that have been written by the account.
    ///     [7]: tags - List of tags that have been written for the account.
    ///     [8]: custom - List of custom data that has been written for the account.
    function assembleAccountData(
        address _account
    ) external view returns (string[][] memory) {
        string[][] memory accountData = new string[][](9);
        if (permissions[_account].composable) {
            accountData[0] = assembleBasicData(_account);
            accountData[1] = assembleAdditionalLinks(_account);
            accountData[2] = assembleAssociatedAccounts(_account);
            accountData[3] = assembleRespecters(_account);
            accountData[4] = assembleRespecting(_account);
            accountData[5] = assembleNotesReceived(_account);
            accountData[6] = assembleNotesSent(_account);
            accountData[7] = assembleTags(_account);
            accountData[8] = assembleCustomData(_account);
        }
        return accountData;
    }

    /// @notice Returns an account's basic data in string format.
    /// @dev The function converts address and boolean values into string format for uniformity.
    /// The boolean values are returned as "true" or "false" strings.
    /// The function returns an empty array if the EtherEthos's composability is not active or if the account is blocked.
    /// Please note that PFP ownership is not validated in this contract,
    /// and ownership might need to be validated when the data is being composed live in third party applications.
    /// @param _account The account whose data is to be retrieved.
    /// @return basicData A string array containing the basic account data.
    ///     Indecies structure:
    ///     [0]: alias - The account's alias.
    ///     [1]: detail - Detailed information related to the account.
    ///     [2]: socialLink - The socialLink set by the account.
    ///     [3]: website - The website set by the account.
    ///     [4]: gallery - The gallery set by the account.
    ///     [5]: priorityLink - The priorityLink set by the account.
    ///     [6]: pfp contract - The address of the contract of the profile picture (PFP) as a string.
    ///     [7]: pfp tokenId - The token ID of the PFP as a string.
    ///     [8]: ping - The time that the account was last pinged.
    function assembleBasicData(
        address _account
    ) public view returns (string[] memory) {
        if (!permissions[_account].composable) {
            return new string[](9);
        }
        Basics memory basic = basics[_account];
        string[] memory basicData = new string[](9);
        basicData[0] = basic.accountAlias;
        basicData[1] = basic.detail;
        basicData[2] = basic.socialLink;
        basicData[3] = basic.website;
        basicData[4] = basic.gallery;
        basicData[5] = Strings.toString(basic.priorityLink);
        basicData[6] = _addrToStr(basic.pfpContract);
        basicData[7] = Strings.toString(basic.pfpTokenId);
        basicData[8] = Strings.toString(basic.ping);
        return basicData;
    }

    /// @notice Returns the account's link data as pairs of link and detail.
    /// @dev The function returns an empty array if the EtherEthos's composability is not active or if the account is blocked.
    /// The returned indices do not match the indices of the storage array due to the way the data is formatted for return.
    /// @param _account The account whose link data is to be retrieved.
    /// @return additionalLinksArray A string array containing the additional link data,
    /// with alternating link and detail values.
    ///    Indecies structure:
    ///    [0]: link - The first link of the account.
    ///    [1]: detail - The detail of the first link.
    ///    [2]: link - The second link of the account.
    ///    [3]: detail - The detail of the second link.
    ///    etc.
    function assembleAdditionalLinks(
        address _account
    ) public view returns (string[] memory) {
        if (!permissions[_account].composable) {
            return new string[](0);
        }
        uint256 linksCount = additionalLinks[_account].length;
        string[] memory additionalLinksArray = new string[](linksCount * 2);
        for (uint256 i = 0; i < linksCount; i++) {
            additionalLinksArray[i * 2] = additionalLinks[_account][i].k;
            additionalLinksArray[i * 2 + 1] = additionalLinks[_account][i].v;
        }
        return additionalLinksArray;
    }

    /// @notice Returns an account's associated accounts and their details.
    /// @dev The function returns an empty array if the EtherEthos's composability is not active or if the account is blocked.
    /// The returned indices do not match the indices of the storage array due to the way the data is formatted for return.
    /// @param _account The account whose associated accounts and details are to be retrieved.
    /// @return associatedAccountsArray A string array containing associated account data,
    /// with alternating associatedAccount address and detail values.
    ///    Indices structure:
    ///    [0]: associatedAccount - The address of the first associated account.
    ///    [1]: detail - The detail of the first associated account.
    ///    [2]: associatedAccount - The address of the second associated account.
    ///    [3]: detail - The detail of the second associated account.
    ///    etc.
    function assembleAssociatedAccounts(
        address _account
    ) public view returns (string[] memory) {
        if (!permissions[_account].composable) {
            return new string[](0);
        }
        uint256 associatedAccountsCount = associatedAccounts[_account].length;
        string[] memory associatedAccountsArray = new string[](
            associatedAccountsCount * 2
        );
        for (uint256 i = 0; i < associatedAccountsCount; i++) {
            associatedAccountsArray[i * 2] = _addrToStr(
                associatedAccounts[_account][i].k
            );
            associatedAccountsArray[i * 2 + 1] = associatedAccounts[_account][i]
                .v;
        }
        return associatedAccountsArray;
    }

    /// @notice Returns a list of accounts that have respected a specific account.
    /// @dev The function returns an empty array if the EtherEthos's composability is not active or if the account is blocked.
    /// @param _account The account whose respecters are to be retrieved.
    /// @return respectersArray A string array containing the addresses of the accounts that have respected the _account.
    function assembleRespecters(
        address _account
    ) public view returns (string[] memory) {
        if (!permissions[_account].composable) {
            return new string[](0);
        }
        uint256 respectersCount = respecters[_account].length;
        string[] memory respectersArray = new string[](respectersCount);
        for (uint256 i = 0; i < respectersCount; i++) {
            respectersArray[i] = _addrToStr(respecters[_account][i]);
        }
        return respectersArray;
    }

    /// @notice Returns a list of accounts that a specific account has respected.
    /// @dev The function returns an empty array if the EtherEthos's composability is not active or if the account is blocked.
    /// @param _account The account whose respecting accounts are to be retrieved.
    /// @return respectingArray A string array containing the addresses of the accounts that _account has respected.
    function assembleRespecting(
        address _account
    ) public view returns (string[] memory) {
        if (!permissions[_account].composable) {
            return new string[](0);
        }
        uint256 respectingCount = respecting[_account].length;
        string[] memory respectingArray = new string[](respectingCount);
        for (uint256 i = 0; i < respectingCount; i++) {
            respectingArray[i] = _addrToStr(respecting[_account][i]);
        }
        return respectingArray;
    }

    /// @notice Returns the custom data of a specific account.
    /// @dev The function returns an empty array if the EtherEthos's composability is not active or if the account is blocked.
    /// @param _account The account whose custom data is to be retrieved.
    /// @return customDataArray A string array containing one element - the custom data of the _account.
    function assembleCustomData(
        address _account
    ) public view returns (string[] memory) {
        if (!permissions[_account].composable) {
            return new string[](0);
        }
        string[] memory customDataArray = new string[](1);
        customDataArray[0] = custom[_account];
        return customDataArray;
    }

    /// @notice Returns the tags of a specific account.
    /// @dev The function returns an empty array if the EtherEthos's composability is not active or if the account is blocked.
    /// @param _account The account whose tags are to be retrieved.
    /// @return tagsArray A string array containing the tags of the _account.
    function assembleTags(
        address _account
    ) public view returns (string[] memory) {
        if (!permissions[_account].composable) {
            return new string[](0);
        }
        return tags[_account];
    }

    /// @notice Returns an account's notes and their authors.
    /// @dev The function returns an empty array if the account doesn't have any notes or if the note writer is no longer respected.
    /// The returned indices do not match the indices of the storage array due to the way the data is formatted for return.
    /// @param _account The account whose notes are to be retrieved.
    /// @return notesArray A string array containing note data,
    /// with alternating note writer address and note text values.
    ///    Indices structure:
    ///    [0]: noteWriter - The address of the first note writer.
    ///    [1]: note - The note written by the first note writer.
    ///    [2]: noteWriter - The address of the second note writer.
    ///    [3]: note - The note written by the second note writer.
    ///    etc.
    function assembleNotesReceived(
        address _account
    ) public view returns (string[] memory) {
        if (!permissions[_account].composable) {
            return new string[](0);
        }
        uint256 notesCount = notesReceived[_account].length;
        string[] memory notesArray = new string[](notesCount * 2);
        for (uint256 i = 0; i < notesCount; i++) {
            notesArray[i * 2] = _addrToStr(notesReceived[_account][i].k);
            notesArray[i * 2 + 1] = notesReceived[_account][i].v;
        }
        return notesArray;
    }

    /// @notice Returns an account's sent notes along with their recipients and the note content.
    /// @dev The function returns an empty array if the account hasn't written any notes or if notes written were deleted.
    /// @param _account The account whose sent notes and their contents are to be retrieved.
    /// @return notesArray A string array containing note data,
    /// with alternating note recipient address and note text values.
    ///    Indices structure:
    ///    [0]: noteRecipient - The address of the first note writer.
    ///    [1]: note - The note written for this recipient.
    ///    [2]: noteRecipient - The address of the second note writer.
    ///    [3]: note - The note written for this recipient.
    ///    etc.
    function assembleNotesSent(
        address _account
    ) public view returns (string[] memory) {
        uint256 notesCount = notesSent[_account].length;
        string[] memory notesArray = new string[](notesCount * 2);
        for (uint256 i = 0; i < notesCount; i++) {
            address recipient = notesSent[_account][i];
            // Find the index of the note in the recipient's notesReceived array using noteWritersIndex
            uint256 noteIndex = noteWritersIndex[recipient][_account];
            // Retrieve the note content from the recipient's notesReceived array
            string memory noteContent = notesReceived[recipient][noteIndex].v;
            notesArray[i * 2] = _addrToStr(recipient);
            notesArray[i * 2 + 1] = noteContent;
        }
        return notesArray;
    }

    /// @notice Internal function to check the length of a string.
    /// @dev This function is used to check the length of strings passed to the contract, and reverts if the string is too long.
    /// @param _str The string whose length is being checked.
    /// @param _labelIndex The index for the error message to be displayed if the string is too long.
    function _checkStringLength(
        string memory _str,
        uint256 _maxLength,
        uint256 _labelIndex
    ) internal pure {
        string[8] memory labels = [
            "Alias",
            "Detail",
            "Social",
            "Web",
            "Gallery",
            "Link",
            "Tag",
            "Note"
        ];
        string memory _errorMsg = string(abi.encodePacked(labels[_labelIndex], " too long"));
        require(bytes(_str).length < _maxLength + 1, _errorMsg);
    }

    /// @notice Activates a EtherEthos's composability for a specific account.
    /// @dev This internal function used to mark an account as allowing composability and incrementing the total count of composable EEs.
    /// An event, Composable, is emitted upon the successful activation of EtherEthos composability.
    /// @param _account The account for which EtherEthos composability will be activated.
    function _activateComposability(address _account) internal {
        if (!permissions[_account].composable) {
            permissions[_account].composable = true;
            activeEEs++;
            emit Composable(_account, true);
        }
    }

    /// @notice Deactivates a EtherEthos's composability for a specific account.
    /// @dev This internal function used to mark an account as not allowing composability and decrementing the total count of composable EEs.
    /// An event, Composable, is emitted upon the successful deactivation of EtherEthos composability.
    /// @param _account The account for which EtherEthos composability will be deactivated.
    function _deactivateComposability(address _account) internal {
        permissions[_account].composable = false;
        activeEEs--;
        emit Composable(_account, false);
    }

    /// @notice Converts an address to its string representation.
    /// @dev This is a shortcut function used internally to call OpenZeppelin's toHexString function.
    /// @param _address The address to convert into a string.
    /// @return string representation of the input address.
    function _addrToStr(
        address _address
    ) internal pure returns (string memory) {
        return Strings.toHexString(uint160(_address), 20);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";
import "./math/SignedMath.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toString(int256 value) internal pure returns (string memory) {
        return string(abi.encodePacked(value < 0 ? "-" : "", toString(SignedMath.abs(value))));
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1, "Math: mulDiv overflow");

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
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