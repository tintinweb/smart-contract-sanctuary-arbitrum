/**
 *Submitted for verification at Arbiscan.io on 2023-08-30
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//Control who can access various functions.
contract AccessControl {
    address payable public creatorAddress;
    mapping(address => bool) public admins;

    modifier onlyCREATOR() {
        require(
            msg.sender == creatorAddress,
            "You are not the creator of this contract"
        );
        _;
    }

    modifier onlyADMINS() {
        require(admins[msg.sender] == true, "Not an admin");
        _;
    }

    // Constructor
    constructor() {
        creatorAddress = payable(0x813dd04A76A716634968822f4D30Dfe359641194);
    }

    //Admins are contracts or addresses that have write access
    function addAdmin(address _newAdmin) public onlyCREATOR {
        if (admins[_newAdmin] == false) {
            admins[_newAdmin] = true;
        }
    }

    function removeAdmin(address _oldAdmin) public onlyCREATOR {
        if (admins[_oldAdmin] == true) {
            admins[_oldAdmin] = false;
        }
    }
}

//Interface to TAC Contract
abstract contract ITAC {
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual returns (bool);

    function balanceOf(address account) external view virtual returns (uint256);
}

abstract contract ITACTreasury {
    function awardTAC(
        address winner,
        address loser,
        address referee
    ) public virtual;

    function awardTrainingTAC(address athlete, address referee) public virtual;
}

contract RecordMatches is AccessControl {
    /////////////////////////////////////////////////DATA STRUCTURES AND GLOBAL VARIABLES ///////////////////////////////////////////////////////////////////////

    uint256 public numUsers = 0; //total number of user profiles, independent of number of addresses with balances
    uint64 public numMatches = 0; //total number of matches recorded
    uint16 public numEvents = 0; //number of events created

    //Main data structure to hold info about an athlete
    struct User {
        address userAddress; //since the address is unique this also serves as their id.
        uint8 allowedMatches;
        uint64[] matches; // Id numbers of the matches
        uint64[] trainings; // Id numbers of the trainings
    }

    // Main data structure to hold info about a match
    struct Match {
        uint64 id;
        address winner; //address (id) of the athlete who won
        uint8 winnerPoints;
        address loser; //address (id) of the athlete who lost
        uint8 loserPoints;
        address referee; //Who recorded the match
        uint64 time;
        string notes;
    }
    // Main mapping storing an Match record for each match id.
    Match[] public allMatches;

    // Main data structure to hold info about a training

    struct Training {
        uint64 id;
        address athlete;
        address referee;
        uint8 info;
        uint64 time;
    }

    Training[] public allTrainings;

    address[] public allUsersById;

    // Main mapping storing an athlete record for each address.
    mapping(address => User) public allUsers;

    bool public requireMembership = true;

    address public TACContract = 0xFa51B42d4C9EA35F1758828226AaEdBeC50DD54E;
    address public tACTreasuryContract =
        0x1691D63825Bca3352f66F55EC616f6340BbD63e8;

    //The amount of Hwangs required to spar a match.
    uint public matchCost = 10000000000000000000;

    /////////////////////////////////////////////////////////CONTRACT CONTROL FUNCTIONS //////////////////////////////////////////////////

    function changeParameters(
        address _TACContract,
        address _tACTreasuryContract,
        uint _matchCost,
        bool _requireMembership
    ) external onlyCREATOR {
        TACContract = _TACContract;
        tACTreasuryContract = _tACTreasuryContract;
        matchCost = _matchCost;
        requireMembership = _requireMembership;
    }

    /////////////////////////////////////////////////////////USER INFO FUNCTIONS  //////////////////////////////////////////////////

    //function which sets information for the address which submitted the transaction.
    function setUser(address newUser) public {
        bool zeroMatches = false;

        if (allUsers[newUser].userAddress == address(0)) {
            //new user so add to number of users
            numUsers++;
            allUsersById.push(newUser);
            zeroMatches = true;
        }

        User storage user = allUsers[newUser];
        user.userAddress = newUser;
        if (zeroMatches == true) {
            user.allowedMatches = 0;
        }
    }

    //Function which specifies how many matches a user has left.
    //Only coop members have approved matches and only referees need them.
    //Set 0 to remove a user's ability to record matches.
    function setUserAllowedMatches(
        address user,
        uint8 newApprovalNumber
    ) public onlyADMINS {
        allUsers[user].allowedMatches = newApprovalNumber;
    }

    //Function which returns user information for the specified address.
    function getUser(
        address _address
    )
        public
        view
        returns (
            address userAddress,
            uint64[] memory matches,
            uint8 allowedMatches
        )
    {
        User storage user = allUsers[_address];
        userAddress = user.userAddress;
        matches = user.matches;
        allowedMatches = user.allowedMatches;
    }

    /////////////////////////////////////////////////////////MATCH FUNCTIONS  //////////////////////////////////////////////////

    function recordMatch(
        address _winner,
        uint8 _winnerPoints,
        address _loser,
        uint8 _loserPoints,
        address _referee,
        string memory _notes
    ) public {
        require(
            (allUsers[_referee].allowedMatches > 0 ||
                requireMembership == false),
            "Members must have available allowed matches"
        );
        require(msg.sender == _referee, "The referee must record the match");
        require(
            (_winner != _loser) &&
                (_winner != _referee) &&
                (_loser != _referee),
            "The only true battle is against yourself, but can't count it here."
        );

        if (allUsers[_winner].userAddress == address(0)) {
            setUser(_winner);
        }

        if (allUsers[_loser].userAddress == address(0)) {
            setUser(_loser);
        }
        

        //Decrement the referee's match allowance
        if (requireMembership == true) {
            allUsers[_referee].allowedMatches -= 1;
        }

        // Create the match
        Match memory proposedMatch;
        proposedMatch.id = numMatches;
        proposedMatch.winner = _winner;
        proposedMatch.winnerPoints = _winnerPoints;
        proposedMatch.loser = _loser;
        proposedMatch.loserPoints = _loserPoints;
        proposedMatch.referee = _referee;
        proposedMatch.time = uint64(block.timestamp);
        proposedMatch.notes = _notes;

        // Add it to the list of each person as well as the overall list.
        allMatches.push(proposedMatch);
        allUsers[_winner].matches.push(numMatches);
        allUsers[_loser].matches.push(numMatches);
        allUsers[_referee].matches.push(numMatches);

        numMatches++;

        ITAC TAC = ITAC(TACContract);

        //Transfer the Entry fee in TAC from each athlete.
        TAC.transferFrom(_loser, creatorAddress, matchCost);
        TAC.transferFrom(_winner, creatorAddress, matchCost);

        ITACTreasury TACTreasury = ITACTreasury(tACTreasuryContract);
        //Award bonus TAC
        TACTreasury.awardTAC(_winner, _loser, _referee);
    }

    function overwriteMatch(
        uint64 id,
        address _winner,
        uint8 _winnerPoints,
        address _loser,
        uint8 _loserPoints,
        string memory _notes
    ) public {
        // The referee only can overwrite matches
        require(
            allMatches[id].referee == msg.sender,
            "Only the referee may overwrite a match"
        );

        require(
            (_winner != _loser) &&
                (_winner != msg.sender) &&
                (_loser != msg.sender),
            "The only true battle is against yourself, but can't count it here."
        );

        if (allUsers[_winner].userAddress == address(0)) {
            setUser(_winner);
        }

        if (allUsers[_loser].userAddress == address(0)) {
            setUser(_loser);
        }

        // Overwrite the match.
        allMatches[id].winner = _winner;
        allMatches[id].winnerPoints = _winnerPoints;
        allMatches[id].loser = _loser;
        allMatches[id].loserPoints = _loserPoints;
        allMatches[id].notes = _notes;
    }

    function getMatch(
        uint64 _id
    )
        public
        view
        returns (
            uint64 id,
            address winner,
            uint8 winnerPoints,
            address loser,
            uint8 loserPoints,
            uint64 time,
            string memory notes,
            address referee
        )
    {
        Match memory matchToGet = allMatches[_id];
        id = matchToGet.id;
        winner = matchToGet.winner;
        winnerPoints = matchToGet.winnerPoints;
        loser = matchToGet.loser;
        loserPoints = matchToGet.loserPoints;
        time = matchToGet.time;
        notes = matchToGet.notes;
        referee = matchToGet.referee;
    }

    /////////////////////////////////////////////////////////TRAINING FUNCTIONS  //////////////////////////////////////////////////

    function recordTraining(address _athlete, uint8 _info) public {
        require(
            (allUsers[msg.sender].allowedMatches > 0 ||
                requireMembership == false),
            "Referee must have available allowed matches"
        );
        require(msg.sender != _athlete, "You cannot record your own training");

        //Decrement the referee's match allowance
        if (requireMembership == true) {
            allUsers[msg.sender].allowedMatches -= 1;
        }

        if (allUsers[_athlete].userAddress == address(0)) {
            setUser(_athlete);
        }

        // Create the proposed training
        Training memory training;
        training.id = uint64(allTrainings.length);
        training.athlete = _athlete;
        training.info = _info;
        training.referee = msg.sender;
        training.time = uint64(block.timestamp);

        // Add it to the list of each person as well as the overall list.
        allTrainings.push(training);
        allUsers[_athlete].trainings.push(training.id);
        allUsers[msg.sender].trainings.push(training.id);

        ITAC TAC = ITAC(TACContract);

        //Transfer 10 TAC from the athlete.
        TAC.transferFrom(_athlete, creatorAddress, matchCost);

        ITACTreasury TACTreasury = ITACTreasury(tACTreasuryContract);

        //Award bonus TAC
        TACTreasury.awardTrainingTAC(_athlete, msg.sender);
    }

    function getAllTrainings() public view returns (Training[] memory) {
        return allTrainings;
    }
}