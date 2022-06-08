// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.4;

import "./libraries/Data.sol";
import "./libraries/Fork.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IDestinationContract.sol";
import "./MessageDock/CrossDomainHelper.sol";
// import "hardhat/console.sol";

contract NewDestination is IDestinationContract, CrossDomainHelper, Ownable {
    using SafeERC20 for IERC20;
    using HashOnions for mapping(uint256 => HashOnions.Info);
    using Fork for mapping(bytes32 => Fork.Info);

    address private tokenAddress;
    address private poolTokenAddress;

    mapping(bytes32 => Fork.Info) public hashOnionForks;
    mapping(uint256 => mapping(bytes32 => bool)) private isRespondOnions;
    mapping(uint256 => HashOnions.Info) private hashOnions;
    mapping(bytes32 => address) private onionsAddress; // !!! Conflict with using zk scheme, new scheme needs to be considered when using zk

    mapping(address => uint256) private source_chainIds;

    mapping(address => bool) private _committerDeposits; // Submitter's bond record

    uint256 public immutable ONEFORK_MAX_LENGTH = 5; // !!! The final value is 50 , the higher the value, the longer the wait time and the less storage consumption
    uint256 public immutable DEPOSIT_AMOUNT = 1 * 10**18; // !!! The final value is 2 * 10**17

    /*
	1. every LP need deposit `DEPOSIT_AMOUNT` ETH, DEPOSIT_AMOUNT = OnebondGaslimit * max_fork.length * Average_gasPrice 
	2. when LP call zfork()、mfork()、claim(). lock deposit, and unlock the preHashOnions LP's deposit. 
	3. When bonder is settling `middle fork`, will get `DEPOSIT_AMOUNT` ETH back from destContract. 
	4. LP's deposit can only be withdrawn if they are unlocked.
	5. No one wants to pay for someone else's mistakes, so the perpetrator's deposit will never be unlocked
    */

    constructor(address _tokenAddress, address _dockAddr)
        CrossDomainHelper(_dockAddr)
    {
        tokenAddress = _tokenAddress;
    }

    function _onlyApprovedSources(address _sourceSender, uint256 _sourChainId)
        internal
        view
        override
    {
        require(_sourChainId != 0, "ZERO_CHAINID");
        require(source_chainIds[_sourceSender] == _sourChainId, "NOTAPPROVE");
    }

    /*
     * call from source
     * TODO it is not already ok
     */
    function bondSourceHashOnion(uint256 chainId, bytes32 hashOnion)
        external
        sourceSafe
    {
        HashOnions.Info memory info = hashOnions[chainId];

        if (info.onWorkHashOnion == "" || info.onWorkHashOnion == hashOnion) {
            hashOnions[chainId].onWorkHashOnion = hashOnion;
        }

        hashOnions[chainId].sourceHashOnion = hashOnion;
    }

    /**
     * Add domain. Init hashOnionForks, bind source & chainId
     */
    function addDomain(uint256 chainId, address source) external onlyOwner {
        hashOnionForks.initialize(chainId, ONEFORK_MAX_LENGTH);
        source_chainIds[source] = chainId;
    }

    // TODO need deposit ETH
    function becomeCommiter() external {
        _committerDeposits[msg.sender] = true;
    }

    function getHashOnionFork(
        uint256 chainId,
        bytes32 hashOnion,
        uint8 index
    ) external view returns (Fork.Info memory) {
        return hashOnionForks.get(chainId, hashOnion, index);
    }

    function getHashOnionInfo(uint256 chainId)
        external
        view
        returns (HashOnions.Info memory)
    {
        return hashOnions[chainId];
    }

    /* 
        A. Ensure that a single correct fork link is present:
        There are three behaviors of commiters related to fork:
        1. Create a 0-bit fork
        2. Create a non-zero fork
        3. Add OnionHead to any Fork

        The rules are as follows:
        1. Accept any submission, zero-bit Fork needs to pass in PreForkkey
        2. Fork starting with non-zero bits, length == ONEFORK_MAX_LENGTH - index (value range 1-49)

        B. Ensure that only the only correct fork link will be settled:
        1. onWorkHashOnion's index % ONEFORK_MAX_LENGTH == ONEFORK_MAX_LENGTH
        2. When bonding, the bond is the bond from the back to the front. If the fork being bonded is a non-zero fork, you need to provide preForkKey, onions1, onions2, and the parameters must meet the following conditions:
           2.1 f(onions) == preFork.onionHead
           2.2 onions[0] != fork.key //If there is an equal situation, then give the allAmount of the fork to onions[0].address . The bonder gets a deposit to compensate the gas fee.
           2.3 fork.onionHead == onWorkHashOnion

        C. Guarantee that bad commits will be penalized:
        1. CommiterA deposits the deposit, initiates a commit or fork, and the deposit is locked
        2. The margin can only be unlocked by the addition of another Committer  
    */

    // if index % ONEFORK_MAX_LENGTH == 0
    function zFork(
        uint256 chainId,
        bytes32 workForkKey,
        address dest,
        uint256 amount,
        uint256 fee,
        bool _isRespond
    ) external override {
        (Fork.Info memory workFork, Fork.Info memory newFork) = hashOnionForks
            .createZFork(chainId, workForkKey, dest, amount, fee);

        if (_committerDeposits[msg.sender] == false) {
            // If same commiter, don't need deposit
            // For Debug
            // require(msg.sender == workFork.lastCommiterAddress, "a2");
        }

        // Determine whether the maker only submits or submits and responds
        if (_isRespond) {
            IERC20(tokenAddress).safeTransferFrom(msg.sender, dest, amount);
        } else {
            // !!! Whether to add the identification position of the index
            isRespondOnions[chainId][newFork.onionHead] = true;
        }

        // Locks the new committer's bond, unlocks the previous committer's bond state
        if (workFork.lastCommiterAddress != msg.sender) {
            _committerDeposits[workFork.lastCommiterAddress] = true;
            _committerDeposits[msg.sender] = false;
        }

        emit newClaim(dest, amount, fee, 0, newFork.onionHead);
    }

    // just deppend
    function claim(
        uint256 chainId,
        bytes32 workForkKey,
        uint256 _workIndex,
        Data.TransferData[] calldata _transferDatas,
        bool[] calldata _isResponds
    ) external override {
        // incoming data length is correct
        require(_transferDatas.length > 0, "a1");

        // positioning fork
        Fork.Info memory workFork = hashOnionForks[workForkKey];

        // Determine whether this fork exists
        require(workFork.length > 0, "fork is null"); //use length

        // Determine the eligibility of the submitter
        if (_committerDeposits[msg.sender] == false) {
            // For Debug
            // require(msg.sender == workFork.lastCommiterAddress, "a3");
        }

        // Determine whether someone has submitted it before. If it has been submitted by the predecessor, tx.origin thinks that the submission is incorrect and can be forked and resubmitted through forkFromInput
        // !!! Avoid duplicate submissions
        require(_workIndex == workFork.length, "b2");

        // Judge _transferDatas not to exceed the limit
        require(_workIndex + _transferDatas.length <= ONEFORK_MAX_LENGTH, "a2");

        bytes32 onionHead = workFork.onionHead;
        bytes32 destOnionHead = workFork.destOnionHead;
        uint256 allAmount = 0;
        // just append
        for (uint256 i; i < _transferDatas.length; i++) {
            onionHead = keccak256(
                abi.encode(onionHead, keccak256(abi.encode(_transferDatas[i])))
            );
            if (_isResponds[i]) {
                IERC20(tokenAddress).safeTransferFrom(
                    msg.sender,
                    _transferDatas[i].destination,
                    _transferDatas[i].amount
                );
            } else {
                // TODO need change to transferData hash
                isRespondOnions[chainId][onionHead] = true;
            }
            destOnionHead = keccak256(
                abi.encode(destOnionHead, onionHead, msg.sender)
            );
            allAmount += _transferDatas[i].amount + _transferDatas[i].fee;

            emit newClaim(
                _transferDatas[i].destination,
                _transferDatas[i].amount,
                _transferDatas[i].fee,
                _workIndex + i,
                onionHead
            );
        }

        // change deposit , deposit token is ETH , need a function to deposit and with draw
        if (workFork.lastCommiterAddress != msg.sender) {
            _committerDeposits[workFork.lastCommiterAddress] = true;
            _committerDeposits[msg.sender] = false;
        }

        workFork = Fork.Info({
            onionHead: onionHead,
            destOnionHead: destOnionHead,
            allAmount: allAmount + workFork.allAmount,
            length: _workIndex + _transferDatas.length,
            lastCommiterAddress: msg.sender,
            needBond: workFork.needBond
        });

        // storage
        hashOnionForks.update(workForkKey, workFork);
    }

    // if source index % ONEFORK_MAX_LENGTH != 0
    function mFork(
        uint256 chainId,
        bytes32 _lastOnionHead,
        bytes32 _lastDestOnionHead,
        uint8 _index,
        Data.TransferData calldata _transferData,
        bool _isRespond
    ) external override {
        // Determine whether tx.origin is eligible to submit
        require(_committerDeposits[msg.sender] == true, "a3");

        Fork.Info memory newFork = hashOnionForks.createMFork(
            chainId,
            _lastOnionHead,
            _lastDestOnionHead,
            _index,
            _transferData
        );

        // Determine whether the maker only submits or submits and also responds, so as to avoid the large amount of unresponsiveness of the maker and block subsequent commints
        if (_isRespond) {
            IERC20(tokenAddress).safeTransferFrom(
                msg.sender,
                _transferData.destination,
                _transferData.amount
            );
        } else {
            isRespondOnions[chainId][newFork.onionHead] = true;
        }

        // Freeze Margin
        _committerDeposits[msg.sender] = false;
    }

    // clearing zfork
    function zbond(
        uint256 chainId,
        bytes32 hashOnion,
        bytes32 _preHashOnion,
        Data.TransferData[] calldata _transferDatas,
        address[] calldata _commiters
    ) external override {
        // incoming data length is correct
        require(_transferDatas.length > 0, "a1");
        require(_commiters.length == _transferDatas.length, "a2");

        bytes32 workForkKey = Fork.generateForkKey(chainId, hashOnion, 0);
        Fork.Info memory workFork = hashOnionForks[workForkKey];

        // Judging whether this fork exists && Judging that the fork needs to be settled
        require(workFork.needBond, "a3");

        // Determine whether the onion of the fork has been recognized
        require(
            workFork.onionHead == hashOnions[chainId].onWorkHashOnion,
            "a4"
        ); //use length

        bytes32 preWorkForkKey = Fork.generateForkKey(
            chainId,
            _preHashOnion,
            0
        );
        Fork.Info memory preWorkFork = hashOnionForks[preWorkForkKey];

        // Determine whether this fork exists
        require(preWorkFork.length > 0, "Fork is null"); //use length

        bytes32 onionHead = preWorkFork.onionHead;
        bytes32 destOnionHead = preWorkFork.destOnionHead;
        // repeat
        for (uint256 i; i < _transferDatas.length; i++) {
            onionHead = keccak256(
                abi.encode(onionHead, keccak256(abi.encode(_transferDatas[i])))
            );
            if (isRespondOnions[chainId][onionHead]) {
                address onionAddress = onionsAddress[onionHead];
                if (onionAddress != address(0)) {
                    IERC20(tokenAddress).safeTransfer(
                        onionAddress,
                        _transferDatas[i].amount + _transferDatas[i].fee
                    );
                } else {
                    IERC20(tokenAddress).safeTransfer(
                        _transferDatas[i].destination,
                        _transferDatas[i].amount + _transferDatas[i].fee
                    );
                }
            } else {
                IERC20(tokenAddress).safeTransfer(
                    _commiters[i],
                    _transferDatas[i].amount + _transferDatas[i].fee
                );
            }
            destOnionHead = keccak256(
                abi.encode(destOnionHead, onionHead, _commiters[i])
            );
        }

        // Assert that the replay result is equal to the stored value of the fork, which means that the incoming _transferdatas are valid
        require(destOnionHead == workFork.destOnionHead, "a5");

        // storage workFork
        workFork.needBond = false;
        hashOnionForks.update(workForkKey, workFork);

        // wenbo
        // if(type[forkkey] = 2){
        //     token.transfer(haoren, fork.allmoney/5)
        // }

        // If the prefork also needs to be settled, push the onWorkHashOnion forward a fork
        this.setOnWorkHashOnion(
            chainId,
            preWorkFork.onionHead,
            preWorkFork.needBond
        );

        // !!! Reward bonder
    }

    // Settlement non-zero fork
    function mbond(
        uint256 chainId,
        bytes32 preWorkForkKey,
        Data.MForkData[] calldata _mForkDatas,
        Data.TransferData[] calldata _transferDatas,
        address[] calldata _commiters
    ) external override {
        require(_mForkDatas.length > 1, "a1");

        // incoming data length is correct
        require(_transferDatas.length == ONEFORK_MAX_LENGTH, "a1");
        require(_transferDatas.length == _commiters.length, "a2");
        // bytes32[] memory _onionHeads;
        // checkForkData(_mForkDatas[0], _mForkDatas[0], _onionHeads, 0, chainId);

        Fork.Info memory preWorkFork = hashOnionForks[preWorkForkKey];

        // Determine whether this fork exists
        require(preWorkFork.length > 0, "Fork is null"); //use length

        (bytes32[] memory onionHeads, bytes32 destOnionHead) = Fork
            .getMbondOnionHeads(preWorkFork, _transferDatas, _commiters);

        // repeat
        uint256 y = 0;
        uint256 i = 0;
        for (; i < _transferDatas.length; i++) {
            /* 
                If this is a fork point, make two judgments
                1. Whether the parallel fork points of the fork point are the same, if they are the same, it means that the fork point is invalid, that is, the bond is invalid. And submissions at invalid fork points will not be compensated
                2. Whether the headOnion of the parallel fork point can be calculated by the submission of the bond, if so, the incoming parameters of the bond are considered valid
            */
            if (y < _mForkDatas.length - 1 && _mForkDatas[y].forkIndex == i) {
                // Determine whether the fork needs to be settled, and also determine whether the fork exists
                checkForkData(
                    _mForkDatas[y == 0 ? 0 : y - 1],
                    _mForkDatas[y],
                    onionHeads,
                    i
                );
                y += 1;
                // !!! Calculate the reward, and reward the bond at the end, the reward fee is the number of forks * margin < margin equal to the wrongtx gaslimit overhead brought by 50 Wrongtx in this method * common gasPrice>
            }
            if (isRespondOnions[chainId][onionHeads[i + 1]]) {
                address onionAddress = onionsAddress[onionHeads[i + 1]];
                if (onionAddress != address(0)) {
                    IERC20(tokenAddress).safeTransfer(
                        onionAddress,
                        _transferDatas[i].amount + _transferDatas[i].fee
                    );
                } else {
                    IERC20(tokenAddress).safeTransfer(
                        _transferDatas[i].destination,
                        _transferDatas[i].amount + _transferDatas[i].fee
                    );
                }
            } else {
                IERC20(tokenAddress).safeTransfer(
                    _commiters[i],
                    _transferDatas[i].amount + _transferDatas[i].fee
                );
            }
        }

        // wenbo
        // type[fokrkey] = 2

        // Debug
        // console.log("i: ", i);
        // console.logBytes32(onionHeads[i]);
        // console.logBytes32(hashOnions[chainId].onWorkHashOnion);
        // console.logBytes32(preWorkFork.onionHead);
        // console.log(preWorkFork.needBond);

        // Assert the replay result, indicating that the fork is legal
        require(onionHeads[i] == hashOnions[chainId].onWorkHashOnion, "a2");
        // Assert that the replay result is equal to the stored value of the fork, which means that the incoming _transferdatas are valid

        // Check destOnionHead
        require(
            destOnionHead ==
                hashOnionForks[_mForkDatas[y].forkKey].destOnionHead,
            "a4"
        );

        // If the prefork also needs to be settled, push the onWorkHashOnion forward a fork
        this.setOnWorkHashOnion(
            chainId,
            preWorkFork.onionHead,
            preWorkFork.needBond
        );

        // !!! Reward bonder
    }

    function checkForkData(
        Data.MForkData calldata preForkData,
        Data.MForkData calldata forkData,
        bytes32[] memory onionHeads,
        uint256 index
    ) internal {
        bytes32 preForkOnionHead = onionHeads[index];
        bytes32 onionHead = onionHeads[index + 1];

        require(hashOnionForks[forkData.forkKey].needBond == true, "b1");
        if (index != 0) {
            // Calculate the onionHead of the parallel fork based on the preonion and the tx of the original path
            preForkOnionHead = keccak256(
                abi.encode(preForkOnionHead, forkData.wrongtxHash[0])
            );
            // If the parallel Onion is equal to the key of forkOnion, it means that forkOnion is illegal
            require(preForkOnionHead != onionHead, "a2");

            // After passing, continue to calculate AFork
            uint256 x = 1;
            while (x < forkData.wrongtxHash.length) {
                preForkOnionHead = keccak256(
                    abi.encode(preForkOnionHead, forkData.wrongtxHash[x])
                );
                x++;
            }
            // Judging that the incoming _wrongTxHash is in line with the facts, avoid bond forgery AFork.nextOnion == BFork.nextOnion
            require(
                preForkOnionHead ==
                    hashOnionForks[preForkData.forkKey].onionHead
            );
        }
        hashOnionForks[forkData.forkKey].needBond = false;
    }

    function buyOneOnion(
        uint256 chainId,
        bytes32 preHashOnion,
        Data.TransferData calldata _transferData
    ) external override {
        bytes32 key = keccak256(
            abi.encode(preHashOnion, keccak256(abi.encode(_transferData)))
        );
        require(isRespondOnions[chainId][key], "a1");
        require(onionsAddress[key] == address(0), "a2");

        IERC20(tokenAddress).safeTransferFrom(
            msg.sender,
            _transferData.destination,
            _transferData.amount
        );

        onionsAddress[key] = msg.sender;
    }

    // max deposit block Limit
    // min deposit funds rate
    // max deposit funds
    function depositWithOneFork(uint256 chainId, bytes32 forkKey) external {
        // DestChildContract child = DestChildContract(chainId_childs[chainId]);
        // fork is deposit = true
        // erc20（tokenAddress）.transferfrom(sender,self,fork.allAmount/10)
    }

    // mfork
    function depositwithMutiMFork(uint256 chainId) external {}

    // block Depostit one fork
    function blockDepositOneFork(uint256 chainId, uint256 forkKeyNum) external {
        // fork is block = true
        // erc20（tokenAddress）.transferfrom(sender,self,fork.allAmount/10)
    }

    // create bond token
    function creatPToken(uint256 chainId, uint256 forkKeyNum) external {
        // requer(type[forkkey] == 1)
        // requer(blocknum[forkkey] + mintime >= nowblocknum )
        // ptoken.mint(fork.allAmount)
        // rentContranct.jieqian(fork.allAmount){
        //     ptoken.transferfrom(sender,self,fork.allamount)
        //     token.transfer(sender)
        // }
    }

    function settlement(uint256 chainId, uint256 forkKeyNum) external {
        // if fork.deposit = true and fork.isblock = false and fork.depositValidBlockNum >= nowBlockNum
        // if token.balanceof(this) < forkAmount do creatBondToken count to self
        // if token.balanceof(lpcontract) >= forkAmount send bondToken to lpContract , and claim token to this
        // if token.balanceof(lpcontract) < forkAmount share token is change to bondToken
        // do zfork , send token to user
        // // if token.balanceof(this) >= forkAmount  do  zfork
    }

    function loanFromLPPool(uint256 amount) internal {
        // send bondToken to LPPool
        // LPPool send real token to dest
        
    }

    // buy bond token
    function buyOneFork(
        uint256 chainId,
        uint256 _forkKey,
        uint256 _forkId
    ) external override {}

    function setOnWorkHashOnion(
        uint256 chainId,
        bytes32 onion,
        bool equal
    ) external {
        HashOnions.Info memory info = hashOnions[chainId];
        if (equal) {
            info.onWorkHashOnion = onion;
        } else {
            // If no settlement is required, it means that the previous round of settlement is completed, and a new value is set
            info.onWorkHashOnion = info.sourceHashOnion;
        }
        hashOnions[chainId] = info;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.4;

library Data {
    struct TransferData {
        address destination;
        uint256 amount;
        uint256 fee;
    }

    struct MForkData {
        uint8 forkIndex;
        bytes32 forkKey;
        bytes32[] wrongtxHash;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.4;

import "./Data.sol";
// import "hardhat/console.sol";

library HashOnions {
    struct Info {
        bytes32 sourceHashOnion;
        bytes32 onWorkHashOnion;
    }
}

library Fork {
    struct Info {
        bytes32 onionHead;
        bytes32 destOnionHead;
        uint256 allAmount;
        uint256 length;
        address lastCommiterAddress;
        bool needBond; // true is need to settle
    }

    function isExist(mapping(bytes32 => Info) storage self, bytes32 forkKey)
        internal
        view
        returns (bool)
    {
        return self[forkKey].length > 0;
    }

    function remove(mapping(bytes32 => Info) storage self, bytes32 forkKey)
        internal
    {
        delete self[forkKey];
    }

    function update(
        mapping(bytes32 => Info) storage self,
        bytes32 forkKey,
        Info memory forkInfo
    ) internal {
        self[forkKey] = forkInfo;
    }

    function get(
        mapping(bytes32 => Info) storage self,
        uint256 chainId,
        bytes32 hashOnion,
        uint8 index
    ) internal view returns (Info memory) {
        bytes32 forkKey = generateForkKey(chainId, hashOnion, index);
        return self[forkKey];
    }

    /// @param chainId Chain's id
    /// @param hashOnion Equal to fork's first Info.onionHead
    /// @param index Fork's index
    function generateForkKey(
        uint256 chainId,
        bytes32 hashOnion,
        uint8 index
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(chainId, hashOnion, index));
    }

    /// @param chainId Chain's id
    /// @param maxLength OneFork max length
    function initialize(
        mapping(bytes32 => Info) storage self,
        uint256 chainId,
        uint256 maxLength
    ) internal {
        bytes32 forkKey = generateForkKey(chainId, bytes32(0), 0);
        require(isExist(self, forkKey) == false);

        update(
            self,
            forkKey,
            Info(bytes32(0), bytes32(0), 0, maxLength, address(0), false)
        );
    }

    /// @param workForkKey Current work fork's key
    function createZFork(
        mapping(bytes32 => Info) storage self,
        uint256 chainId,
        bytes32 workForkKey,
        address dest,
        uint256 amount,
        uint256 fee
    ) internal returns (Info memory _workFork, Info memory _newFork) {
        // Take out the Fork
        Info memory workFork = self[workForkKey];

        // Create a new Fork
        Info memory newFork;

        // set newFork
        newFork.onionHead = keccak256(
            abi.encode(
                workFork.onionHead,
                keccak256(abi.encode(dest, amount, fee))
            )
        );
        bytes32 newForkKey = generateForkKey(chainId, newFork.onionHead, 0);

        // Determine whether there is a fork with newForkKey
        require(isExist(self, newForkKey) == false, "c1");

        newFork.destOnionHead = keccak256(
            abi.encode(workFork.destOnionHead, newFork.onionHead, msg.sender)
        );

        newFork.allAmount += amount + fee;
        newFork.length = 1;
        newFork.lastCommiterAddress = msg.sender;
        newFork.needBond = true;

        // storage
        update(self, newForkKey, newFork);

        _workFork = workFork;
        _newFork = newFork;
    }

    /// @param _lastOnionHead Before wrong fork's onionHead
    /// @param _lastDestOnionHead Before wrong fork's destOnionHead
    function createMFork(
        mapping(bytes32 => Info) storage self,
        uint256 chainId,
        bytes32 _lastOnionHead,
        bytes32 _lastDestOnionHead,
        uint8 _index,
        Data.TransferData calldata _transferData
    ) internal returns (Info memory _newFork) {
        // Create a new Fork
        Fork.Info memory newFork;

        // set newFork
        newFork.onionHead = keccak256(
            abi.encode(_lastOnionHead, keccak256(abi.encode(_transferData)))
        );
        bytes32 newForkKey = Fork.generateForkKey(
            chainId,
            newFork.onionHead,
            _index
        );

        // Determine whether there is a fork with newFork.destOnionHead as the key
        require(isExist(self, newForkKey) == false, "c1");

        newFork.destOnionHead = keccak256(
            abi.encode(_lastDestOnionHead, newFork.onionHead, msg.sender)
        );

        newFork.allAmount += _transferData.amount + _transferData.fee;
        newFork.length = _index + 1;
        newFork.lastCommiterAddress = msg.sender;
        newFork.needBond = true;

        // storage
        update(self, newForkKey, newFork);

        _newFork = newFork;
    }

    function getMbondOnionHeads(
        Info memory preWorkFork,
        Data.TransferData[] calldata _transferDatas,
        address[] calldata _commiters
    )
        internal
        pure
        returns (bytes32[] memory onionHeads, bytes32 destOnionHead)
    {
        // Determine whether this fork exists
        require(preWorkFork.length > 0, "Fork is null"); //use length

        onionHeads = new bytes32[](_transferDatas.length + 1);
        onionHeads[0] = preWorkFork.onionHead;
        destOnionHead = preWorkFork.destOnionHead;

        // repeat
        for (uint256 i; i < _transferDatas.length; i++) {
            onionHeads[i + 1] = keccak256(
                abi.encode(
                    onionHeads[i],
                    keccak256(abi.encode(_transferDatas[i]))
                )
            );

            destOnionHead = keccak256(
                abi.encode(destOnionHead, onionHeads[i + 1], _commiters[i])
            );
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
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

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.4;
import "./libraries/Data.sol";

interface IDestinationContract {
    event newClaim(
        address dest,
        uint256 amount,
        uint256 fee,
        uint256 txindex,
        bytes32 hashOnion
    );
    event newBond(uint256 txIndex, uint256 amount, bytes32 hashOnion);

    function zFork(
        uint256 chainId,
        bytes32 hashOnion,
        address dest,
        uint256 amount,
        uint256 fee,
        bool _isRespond
    ) external;

    function claim(
        uint256 chainId,
        bytes32 hashOnion,
        uint256 _workIndex,
        Data.TransferData[] calldata _transferDatas,
        bool[] calldata _isResponds
    ) external;

    function mFork(
        uint256 chainId,
        bytes32 _lastOnionHead,
        bytes32 _lastDestOnionHead,
        uint8 _index,
        Data.TransferData calldata _transferData,
        bool _isRespond
    ) external;

    function zbond(
        uint256 chainId,
        bytes32 hashOnion,
        bytes32 _preHashOnion,
        Data.TransferData[] calldata _transferDatas,
        address[] calldata _commiters
    ) external;

    function mbond(
        uint256 chainId,
        bytes32 preWorkForkKey,
        Data.MForkData[] calldata _mForkDatas,
        Data.TransferData[] calldata _transferDatas,
        address[] calldata _commiters
    ) external;

    function buyOneOnion(
        uint256 chainId,
        bytes32 preHashOnion,
        Data.TransferData calldata _transferData
    ) external;

    function buyOneFork(
        uint256 chainId,
        uint256 _forkKey,
        uint256 _forkId
    ) external;

    // function getHashOnion(uint256 chainId, address[] calldata _bonderList,bytes32 _sourceHashOnion, bytes32 _bonderListHash) external;
}

// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2019-2021, Offchain Labs, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */


pragma solidity 0.8.4;

import "./IDock_L2.sol";

// TODO: splite CrossDomainHelper, to be sourceCrossDomainHelper and destCrossDomainHelper

abstract contract CrossDomainHelper {
    address public immutable dockAddr;
    
    constructor(
        address _dockAddr
    ){
        dockAddr = _dockAddr;
    }

    modifier sourceSafe {
        require(msg.sender == dockAddr, "NOT_DOCK");
        _onlyApprovedSources(IDock_L2(msg.sender).getSourceSender(),IDock_L2(msg.sender).getSourceChainID());
        _;
    }

    function _onlyApprovedSources(address _sourceSender, uint256 _sourChainId) internal view virtual;

    function crossDomainMassage(address _destAddress, uint256 _destChainID, bytes memory _destMassage) internal {
        IDock_L2(dockAddr).callOtherDomainFunction(_destAddress, _destChainID, _destMassage);
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
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
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
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

// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2019-2021, Offchain Labs, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */


pragma solidity 0.8.4;

interface IDock_L2{
    function callOtherDomainFunction(address _destAddress, uint256 _destChainID, bytes calldata _destMassage) external;
    function getSourceChainID() external view returns (uint256);
    function getSourceSender() external view returns (address);
}