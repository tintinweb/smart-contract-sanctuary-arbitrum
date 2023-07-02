/**
 *Submitted for verification at Arbiscan on 2023-07-02
*/

// SPDX-License-Identifier: UNKNOWN 
pragma solidity >=0.7.0 <0.9.0;

contract MesrsiDiplomaCertificate {

    string public issuer = "Mesrsi gov";
    mapping(string => Certificate) certificates;
    address owner;
    mapping(string => bool) certified;

    struct Certificate { 
        string id;
        string university;
        string grade;
        string speciality;
        string ine;
        uint256 issuingDate;
    }

    event NewCertifications(
        Certificate[] certificates
    );

    constructor() { owner = msg.sender; }

    modifier onlyOwner {
        require(
            msg.sender == owner,
            "Only owner can call this function."
        );
        _;
    }

    function certify(Certificate[] memory ctfs) external onlyOwner {
        for (uint256 i = 0; i < ctfs.length; i++) {
            require(!certified[ctfs[i].id], "Diploma already certified");

            ctfs[i].issuingDate = block.timestamp;
            certificates[ctfs[i].id] = ctfs[i];
            certified[ctfs[i].id] = true;
        }

        emit NewCertifications(ctfs);
    }

    function verify(string calldata id) external view returns(Certificate memory) {
        require(certified[id], "No existing certificate for this diploma id");
        return certificates[id];
    }
}