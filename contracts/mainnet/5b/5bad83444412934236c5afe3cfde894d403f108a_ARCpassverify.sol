/**
 *Submitted for verification at Arbiscan on 2023-06-24
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// File: contracts/ARCpassverify.sol


pragma solidity ^0.8.18;


contract ARCpassverify {
    IERC721 public ARCpasscard;
    address private _ARCpasscard=0x523adD2bdB83b31CeDA68Ca30Ce8C4Ee904A1f56;
    address public owner;

    constructor(){
        ARCpasscard=IERC721(_ARCpasscard);
        owner=msg.sender;
    }

    mapping(address => string) public hwid;
    mapping(uint256 => string) public license;

    function userVerify(address add, string memory _hwid) public view returns(uint256){
        uint256 status=0;
        bytes memory byte_hwid_new = bytes(_hwid);
        bytes memory byte_hwid_old = bytes(hwid[add]);
        if(ARCpasscard.balanceOf(add)>=1){
            if (byte_hwid_new.length == byte_hwid_old.length){
                status=1;
                for(uint i = 0; i < byte_hwid_new.length; i ++) {
                    if(byte_hwid_new[i] != byte_hwid_old[i]){
                        status=0;
                        break;
                    }
                }
            }
        }    
        return status;
    }

    function passVerify(address add) public view returns(uint256){
        uint256 status=0;
        if(ARCpasscard.balanceOf(add)>=1){
            status=1;
        }    
        return status;
    }

    function hwidVerify(address add, string memory _hwid) public view returns(uint256){
        uint256 status=0;
        bytes memory byte_hwid_new = bytes(_hwid);
        bytes memory byte_hwid_old = bytes(hwid[add]);
        if (byte_hwid_new.length == byte_hwid_old.length){
            status=1;
            for(uint i = 0; i < byte_hwid_new.length; i ++) {
                if(byte_hwid_new[i] != byte_hwid_old[i]){
                    status=0;
                    break;
                }
            }
        }
        return status;
    } 

    function checkLicense(uint256 tokenId)public view returns(string memory){
        return license[tokenId];
    }

    function licenseVerify(string memory _license) public view returns(uint256){
        uint256 status=0;
        bytes memory byte_license_new = bytes(_license);
        for(uint j=1 ; j<667 ; j++){
            try this.checkLicense(j) returns(string memory _byte_license_old){
                bytes memory byte_license_old = bytes(_byte_license_old);
                if (byte_license_new.length == byte_license_old.length){
                    status=1;
                    for(uint i = 0; i < byte_license_new.length; i ++) {
                        if(byte_license_new[i] != byte_license_old[i]){
                            status=0;
                            break;
                        }
                    }
                }
            }catch{
                status=0;
            }
            if(status==1){
                break;
            }
        }
        return status;
    } 

    function updataHwid(string memory _hwid) external{
        require(ARCpasscard.balanceOf(msg.sender)>=1, "You don`t have ARCpasscard!");
        hwid[msg.sender]=_hwid;
    }

    function updataLicense(string memory _license, uint256 tokenId) external{
        require(ARCpasscard.balanceOf(msg.sender)>=1, "You don`t have ARCpasscard!");
        require(ARCpasscard.ownerOf(tokenId)==msg.sender, "You are not the owner of this ARCpasscard!");
        license[tokenId]=_license;
    }

    function setNFTaddress(address _address) external byOwner{
        ARCpasscard=IERC721(_address);
    }

    modifier byOwner(){
        require(msg.sender == owner,"Must be owner!");
        _;
    }

}