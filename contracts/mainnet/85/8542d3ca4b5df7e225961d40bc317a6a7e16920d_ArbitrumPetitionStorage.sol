/**
 *Submitted for verification at Arbiscan on 2023-07-20
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;
pragma abicoder v2;
/**
 * @title PetitionStorage
 * @dev 2021 Devgate LLC
 */
contract ArbitrumPetitionStorage {
    /*
     * Data storage structure of a petition
     */
    struct Petition {
        uint32 Uid;		    // An unique identifier of the petition
        string Title;		// A title of the petition
        bytes ContentHash;	// A hash of the petition content
        uint64 Published;	// A timestamp/publish date of the petition
        uint32[] Voters;	// A list of voters of the petition
    }
    /*
     * Storage of petitions
     */
    mapping(uint32 => Petition) public petitions;
    /*
     * Store petition data
     */
    function storePetitionByParams(uint32 uid, string calldata title, bytes calldata contentHash, uint64 published) public {
        // Check petition existence
        Petition storage pet_ = petitions[uid];
        require(pet_.Uid != uid, "Petition already exists.");
	    // Define an empty array of voters
        uint32[] memory voters_;
	    // Construct petition data
        Petition memory petition_ = Petition({
            Uid: uid,
            Title: title,
            ContentHash: contentHash,
            Published: published,
            Voters: voters_
        });
	    // Save petition data
        petitions[uid] = petition_;
    }
    /*
     * Store petition data
     */
    function storePetition(Petition calldata input) public {
        // Check petition existence
        Petition storage pet_ = petitions[input.Uid];
        require(pet_.Uid != input.Uid, "Petition already exists.");
	    // Construct petition data
        Petition memory petition_ = Petition({
            Uid: input.Uid,
            Title: input.Title,
            ContentHash: input.ContentHash,
            Published: input.Published,
            Voters: input.Voters
        });
	    // Save petition data
        petitions[input.Uid] = petition_;
    }
    /*
     * Retrieve petition by it's unique identifier
     */
    function retrievePetition(uint32 pid) public view returns (Petition memory result) {
	    // Find petition by unique identifier
        result = petitions[pid];
        return result;
    }
    /*
     * Vote petition
     */
    function votePetition(uint32 pid, uint32 uid) public {
        // Find petition by unique identifier
        Petition storage petition_ = petitions[pid];
        // Append voter's unique identifier to the petition data
        if (!checkVoter(pid, uid)) {
            petition_.Voters.push(uid);
        }
    }
    /*
     * Bulk-vote petition
     */
    function votePetitionBulk(uint32 pid, uint32[] calldata uids) public {
        // Find petition by unique identifier
        Petition storage petition_ = petitions[pid];
        // Append voter's unique identifier to the petition data
        for(uint i = 0; i < uids.length; i++) {
            if (!checkVoter(pid, uids[i])) {
                petition_.Voters.push(uids[i]);
            }
        }
    }
    function checkVoter(uint32 pid, uint32 uid) private view returns (bool exist){
        exist = false;
        // Find petition by unique identifier
        Petition storage petition_ = petitions[pid];
        // Find voter in the petition voter's list
        uint32[] storage voters_ = petition_.Voters;
        for(uint i = 0; i < voters_.length; i++) {
            if (voters_[i] == uid){
                exist = true;
                break;
            }
        }
        return exist;
    }
    /*
     * Retrieve count of voters at the petition by it's unique identifier
     */
    function retrievePetitionStats(uint32 pId) public view returns (uint result) {
        // Find petition by unique identifier
        Petition storage petition_ = petitions[pId];
        // Retrieve length of an array of voters
        result = petition_.Voters.length;
        return result;
    }
}