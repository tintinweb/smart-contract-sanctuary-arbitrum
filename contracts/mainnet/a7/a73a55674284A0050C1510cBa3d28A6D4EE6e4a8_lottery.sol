/**
 *Submitted for verification at Arbiscan on 2023-07-12
*/

// File: @chainlink/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol


pragma solidity ^0.8.0;

interface AutomationCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}

// File: @chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol


pragma solidity ^0.8.4;

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness. It ensures 2 things:
 * @dev 1. The fulfillment came from the VRFCoordinator
 * @dev 2. The consumer contract implements fulfillRandomWords.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash). Create subscription, fund it
 * @dev and your consumer contract as a consumer of it (see VRFCoordinatorInterface
 * @dev subscription management functions).
 * @dev Call requestRandomWords(keyHash, subId, minimumRequestConfirmations,
 * @dev callbackGasLimit, numWords),
 * @dev see (VRFCoordinatorInterface for a description of the arguments).
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomWords method.
 *
 * @dev The randomness argument to fulfillRandomWords is a set of random words
 * @dev generated from your requestId and the blockHash of the request.
 *
 * @dev If your contract could have concurrent requests open, you can use the
 * @dev requestId returned from requestRandomWords to track which response is associated
 * @dev with which randomness request.
 * @dev See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ.
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request. It is for this reason that
 * @dev that you can signal to an oracle you'd like them to wait longer before
 * @dev responding to the request (however this is not enforced in the contract
 * @dev and so remains effective only in the case of unmodified oracle software).
 */
abstract contract VRFConsumerBaseV2 {
  error OnlyCoordinatorCanFulfill(address have, address want);
  address private immutable vrfCoordinator;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   */
  constructor(address _vrfCoordinator) {
    vrfCoordinator = _vrfCoordinator;
  }

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBaseV2 expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomWords the VRF output expanded to the requested number of words
   */
  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal virtual;

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external {
    if (msg.sender != vrfCoordinator) {
      revert OnlyCoordinatorCanFulfill(msg.sender, vrfCoordinator);
    }
    fulfillRandomWords(requestId, randomWords);
  }
}

// File: @chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol


pragma solidity ^0.8.0;

interface VRFCoordinatorV2Interface {
  /**
   * @notice Get configuration relevant for making requests
   * @return minimumRequestConfirmations global min for request confirmations
   * @return maxGasLimit global max for request gas limit
   * @return s_provingKeyHashes list of registered key hashes
   */
  function getRequestConfig()
    external
    view
    returns (
      uint16,
      uint32,
      bytes32[] memory
    );

  /**
   * @notice Request a set of random words.
   * @param keyHash - Corresponds to a particular oracle job which uses
   * that key for generating the VRF proof. Different keyHash's have different gas price
   * ceilings, so you can select a specific one to bound your maximum per request cost.
   * @param subId  - The ID of the VRF subscription. Must be funded
   * with the minimum subscription balance required for the selected keyHash.
   * @param minimumRequestConfirmations - How many blocks you'd like the
   * oracle to wait before responding to the request. See SECURITY CONSIDERATIONS
   * for why you may want to request more. The acceptable range is
   * [minimumRequestBlockConfirmations, 200].
   * @param callbackGasLimit - How much gas you'd like to receive in your
   * fulfillRandomWords callback. Note that gasleft() inside fulfillRandomWords
   * may be slightly less than this amount because of gas used calling the function
   * (argument decoding etc.), so you may need to request slightly more than you expect
   * to have inside fulfillRandomWords. The acceptable range is
   * [0, maxGasLimit]
   * @param numWords - The number of uint256 random values you'd like to receive
   * in your fulfillRandomWords callback. Note these numbers are expanded in a
   * secure way by the VRFCoordinator from a single random value supplied by the oracle.
   * @return requestId - A unique identifier of the request. Can be used to match
   * a request to a response in fulfillRandomWords.
   */
  function requestRandomWords(
    bytes32 keyHash,
    uint64 subId,
    uint16 minimumRequestConfirmations,
    uint32 callbackGasLimit,
    uint32 numWords
  ) external returns (uint256 requestId);

  /**
   * @notice Create a VRF subscription.
   * @return subId - A unique subscription id.
   * @dev You can manage the consumer set dynamically with addConsumer/removeConsumer.
   * @dev Note to fund the subscription, use transferAndCall. For example
   * @dev  LINKTOKEN.transferAndCall(
   * @dev    address(COORDINATOR),
   * @dev    amount,
   * @dev    abi.encode(subId));
   */
  function createSubscription() external returns (uint64 subId);

  /**
   * @notice Get a VRF subscription.
   * @param subId - ID of the subscription
   * @return balance - LINK balance of the subscription in juels.
   * @return reqCount - number of requests for this subscription, determines fee tier.
   * @return owner - owner of the subscription.
   * @return consumers - list of consumer address which are able to use this subscription.
   */
  function getSubscription(uint64 subId)
    external
    view
    returns (
      uint96 balance,
      uint64 reqCount,
      address owner,
      address[] memory consumers
    );

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @param newOwner - proposed new owner of the subscription
   */
  function requestSubscriptionOwnerTransfer(uint64 subId, address newOwner) external;

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @dev will revert if original owner of subId has
   * not requested that msg.sender become the new owner.
   */
  function acceptSubscriptionOwnerTransfer(uint64 subId) external;

  /**
   * @notice Add a consumer to a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - New consumer which can use the subscription
   */
  function addConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Remove a consumer from a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - Consumer to remove from the subscription
   */
  function removeConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Cancel a subscription
   * @param subId - ID of the subscription
   * @param to - Where to send the remaining LINK to
   */
  function cancelSubscription(uint64 subId, address to) external;

  /*
   * @notice Check to see if there exists a request commitment consumers
   * for all consumers and keyhashes for a given sub.
   * @param subId - ID of the subscription
   * @return true if there exists at least one unfulfilled request for the subscription, false
   * otherwise.
   */
  function pendingRequestExists(uint64 subId) external view returns (bool);
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// File: aidogelottery/lottery.sol


pragma solidity ^0.8.0;







 contract lottery is VRFConsumerBaseV2,AutomationCompatibleInterface{
        IERC20 token;
        IERC20 RecoveryToken;
        IERC20 Betdoge;
        
        VRFCoordinatorV2Interface Mylink;
        address VRFAddr=0x41034678D6C633D8a95c75e1138A360a28bA15d1;
        bytes32 keyHash=0x72d2b016bb5b62912afea355ebf33b91319f828738b111b723b78696b9847b63;
        uint64 s_subId;
        uint16 public requestConfirmations=3;
        uint32 public callbackGasLimit=1500000;
        uint32 numWords=1;
        uint256 public requestId;
        uint256[] public s_randomWords;
       
        address owner;
        address[] public Users;
        mapping(address=>mapping(string=>uint256)) public lotteryUsers;
        uint256 public bettingAmount=10000000000000000;
        uint256 public betdogeAmount=1000000000000;
        address burnAddr=0x000000000000000000000000000000000000dEaD;
        address public markeAddr=0x597424DE0f4dC0DADe9fD406f3a8708d01fa4d56;
        uint256 public timeEnd;
        bool public IsOpen;
        uint256 public LotteryNumber=1;
        mapping(uint256=>uint256[9]) public LotteryList;
        mapping(address=>mapping(uint256=>uint256[])) public UserRecordList;
        address public BetdogeMining=0x597424DE0f4dC0DADe9fD406f3a8708d01fa4d56;

        constructor(uint64 subId) VRFConsumerBaseV2(VRFAddr){
            token=IERC20(0x09E18590E8f76b6Cf471b3cd75fE1A1a9D2B2c2b);
            Betdoge=IERC20(0xC6b3446b551065089Aa4E5897b9D9Be9089a6241);
            owner=msg.sender;
            Mylink=VRFCoordinatorV2Interface(VRFAddr);
            s_subId=subId;
            timeEnd=block.timestamp+60 minutes; 
        }

        modifier checkowner(){
            require(msg.sender==owner,"is not owner");
            _;
        }

        event Openstatus(bool _open);
        event betsuccess(address _user,uint256 _amount);
        event extractToken(address _user);


        function setting(
            uint32 _linkgas,
            uint256 _bettingAmount,
            uint256 _betdogeAmount,
            address _markeAddr,
            uint16 _requestConfirmations,
            address _BetdogeMining
            ) public checkowner{
            callbackGasLimit=_linkgas;
            bettingAmount=_bettingAmount;
            betdogeAmount=_betdogeAmount;
            markeAddr=_markeAddr;
            requestConfirmations=_requestConfirmations;
            BetdogeMining=_BetdogeMining;
        }


        function checkUpkeep(bytes calldata) override external returns (bool upkeepNeeded, bytes memory performData){
            upkeepNeeded=false;
            if(Users.length==100&&IsOpen==false&&block.timestamp>timeEnd){
                upkeepNeeded=true;
            }
            return (upkeepNeeded,"");
        }

        function performUpkeep(bytes calldata ) override external {
                require(Users.length==100&&IsOpen==false&&block.timestamp>timeEnd,"time error");
                requestRandomWords();
        }


        function requestRandomWords() private {
            emit Openstatus(true);
            IsOpen=true;
            requestId=Mylink.requestRandomWords(
                keyHash,
                s_subId,
                requestConfirmations,
                callbackGasLimit,
                numWords
            );
        }
        
        function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)  override internal{
                    require(Users.length==100&&block.timestamp>timeEnd,"time error");
                    s_randomWords=randomWords;
                    start(s_randomWords[0]);
        }



        function Betting(uint256 _amount) public  returns(bool){
               require(token.balanceOf(msg.sender)>=bettingAmount,"_amount not");
               require(_amount==bettingAmount,"_amount not bettingAmount");
               require(token.allowance(msg.sender,address(this))>=_amount,"approve balance is not");
               require(Users.length<100,"users full");
               token.transferFrom(msg.sender,address(this),_amount);
               UserRecordList[msg.sender][LotteryNumber].push(Users.length);
               Users.push(msg.sender);
               lotteryUsers[msg.sender]["betdoge"]+=betdogeAmount;
               emit betsuccess(msg.sender,_amount);
               return true;
        }


        function start(uint256 link_random) private returns(address[9] memory adds,uint256[9] memory randoms){
               randoms=getRandom(link_random);
               for(uint8 i;i<randoms.length;i++){
                      uint256 index=randoms[i];
                      adds[i]=Users[index];
                      lotteryUsers[adds[i]]["aidoge"]+=bettingAmount*10;
               }
               token.transfer(burnAddr,bettingAmount*7);
            //    token.transfer(markeAddr,token.balanceOf(address(this)));
               token.transfer(markeAddr,bettingAmount*3);
               delete Users;
               IsOpen=false;
               timeEnd=block.timestamp+30 minutes;
               LotteryList[LotteryNumber]=randoms;
               LotteryNumber+=1;
               emit Openstatus(false);

        }


        function getLotteryList(uint256 _number) public view returns(uint256[9] memory _arr){
                 _arr=LotteryList[_number];
        }

        function getUserRecordList(address _add,uint256 _number) view public returns(uint256[] memory _userNumbers){
                _userNumbers=UserRecordList[_add][_number];
               
        }



        function _start(uint256 link_random) external checkowner{
                 IsOpen=false;
                 require(Users.length==100&&IsOpen==false&&block.timestamp>timeEnd,"time error");
                 start(link_random);
        }




        function extractAidoge(uint256 _amount)   public returns(bool){
                 require(_amount>0,"_amount must >0");
                 require(lotteryUsers[msg.sender]["aidoge"]>=_amount,"balance is not");
                 token.transfer(msg.sender,_amount);
                 lotteryUsers[msg.sender]["aidoge"]-=_amount;
                 emit extractToken(msg.sender);
                 return true;
        }

        function extractBetdoge(uint256 _amount)  public returns(bool){
                 require(_amount>0,"_amount must >0");
                 require(lotteryUsers[msg.sender]["betdoge"]>=_amount,"balance is not");
                 Betdoge.transferFrom(BetdogeMining,msg.sender,_amount);
                 lotteryUsers[msg.sender]["betdoge"]-=_amount;
                 emit extractToken(msg.sender);
                 return true;
        }

        // function ceshiSetUsers(uint8 _number) public {
        //         for(uint8 i;i<_number;i++){
        //             Users.push(address(0));
        //         }
        // }

        

        // function Recovery(address _TokenAdd,address _to,uint256 _amount) checkowner public returns(bool){
        //        RecoveryToken=IERC20(_TokenAdd);              
        //        RecoveryToken.transfer(_to,_amount);
        //        return true;
        // }

        function Userslen() public view returns(uint256){
            return Users.length;
        }
        

        function getRandom(uint256 link_random) private view returns(uint256[9] memory){
            uint256[9] memory Randoms;
            uint256 random;

            
            for(uint8 i;i<Randoms.length;i++){
                Randoms[i]=100;
            }
            
            for(uint8 i;i<Randoms.length;i++){
                uint8 temp;
                while(true){
                   random=uint256(keccak256(abi.encode(block.timestamp,msg.sender,block.number,i,temp,block.gaslimit,link_random)))%100;
                   if(!isRepeat(Randoms,random)){
                       Randoms[i]=random;
                       break;
                   }
                   temp++;
                }
            }
            return Randoms;
        }

        function isRepeat(uint256[9] memory _arr,uint256 _random) pure private returns(bool){
                 for(uint8 i;i<_arr.length;i++){
                     if(_arr[i]==_random){
                         return true;
                     }
                 }
                 return false;
        }
    
}