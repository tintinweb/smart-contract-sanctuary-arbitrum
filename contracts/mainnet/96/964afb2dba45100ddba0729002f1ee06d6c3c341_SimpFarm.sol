/**
 *Submitted for verification at Arbiscan on 2023-05-15
*/

// File: contracts/IUniswapV2Factory.sol

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}
// File: contracts/Ownable.sol


pragma solidity ^0.8.4;

/// @notice Simple single owner authorization mixin.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/auth/Ownable.sol)
/// @dev While the ownable portion follows [EIP-173](https://eips.ethereum.org/EIPS/eip-173)
/// for compatibility, the nomenclature for the 2-step ownership handover
/// may be unique to this codebase.
abstract contract Ownable {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The caller is not authorized to call the function.
    error Unauthorized();

    /// @dev The `newOwner` cannot be the zero address.
    error NewOwnerIsZeroAddress();

    /// @dev The `pendingOwner` does not have a valid handover request.
    error NoHandoverRequest();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                           EVENTS                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The ownership is transferred from `oldOwner` to `newOwner`.
    /// This event is intentionally kept the same as OpenZeppelin's Ownable to be
    /// compatible with indexers and [EIP-173](https://eips.ethereum.org/EIPS/eip-173),
    /// despite it not being as lightweight as a single argument event.
    event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);

    /// @dev An ownership handover to `pendingOwner` has been requested.
    event OwnershipHandoverRequested(address indexed pendingOwner);

    /// @dev The ownership handover to `pendingOwner` has been canceled.
    event OwnershipHandoverCanceled(address indexed pendingOwner);

    /// @dev `keccak256(bytes("OwnershipTransferred(address,address)"))`.
    uint256 private constant _OWNERSHIP_TRANSFERRED_EVENT_SIGNATURE =
        0x8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e0;

    /// @dev `keccak256(bytes("OwnershipHandoverRequested(address)"))`.
    uint256 private constant _OWNERSHIP_HANDOVER_REQUESTED_EVENT_SIGNATURE =
        0xdbf36a107da19e49527a7176a1babf963b4b0ff8cde35ee35d6cd8f1f9ac7e1d;

    /// @dev `keccak256(bytes("OwnershipHandoverCanceled(address)"))`.
    uint256 private constant _OWNERSHIP_HANDOVER_CANCELED_EVENT_SIGNATURE =
        0xfa7b8eab7da67f412cc9575ed43464468f9bfbae89d1675917346ca6d8fe3c92;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          STORAGE                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The owner slot is given by: `not(_OWNER_SLOT_NOT)`.
    /// It is intentionally choosen to be a high value
    /// to avoid collision with lower slots.
    /// The choice of manual storage layout is to enable compatibility
    /// with both regular and upgradeable contracts.
    uint256 private constant _OWNER_SLOT_NOT = 0x8b78c6d8;

    /// The ownership handover slot of `newOwner` is given by:
    /// ```
    ///     mstore(0x00, or(shl(96, user), _HANDOVER_SLOT_SEED))
    ///     let handoverSlot := keccak256(0x00, 0x20)
    /// ```
    /// It stores the expiry timestamp of the two-step ownership handover.
    uint256 private constant _HANDOVER_SLOT_SEED = 0x389a75e1;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                     INTERNAL FUNCTIONS                     */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Initializes the owner directly without authorization guard.
    /// This function must be called upon initialization,
    /// regardless of whether the contract is upgradeable or not.
    /// This is to enable generalization to both regular and upgradeable contracts,
    /// and to save gas in case the initial owner is not the caller.
    /// For performance reasons, this function will not check if there
    /// is an existing owner.
    function _initializeOwner(address newOwner) internal virtual {
        /// @solidity memory-safe-assembly
        assembly {
            // Clean the upper 96 bits.
            newOwner := shr(96, shl(96, newOwner))
            // Store the new value.
            sstore(not(_OWNER_SLOT_NOT), newOwner)
            // Emit the {OwnershipTransferred} event.
            log3(0, 0, _OWNERSHIP_TRANSFERRED_EVENT_SIGNATURE, 0, newOwner)
        }
    }

    /// @dev Sets the owner directly without authorization guard.
    function _setOwner(address newOwner) internal virtual {
        /// @solidity memory-safe-assembly
        assembly {
            let ownerSlot := not(_OWNER_SLOT_NOT)
            // Clean the upper 96 bits.
            newOwner := shr(96, shl(96, newOwner))
            // Emit the {OwnershipTransferred} event.
            log3(0, 0, _OWNERSHIP_TRANSFERRED_EVENT_SIGNATURE, sload(ownerSlot), newOwner)
            // Store the new value.
            sstore(ownerSlot, newOwner)
        }
    }

    /// @dev Throws if the sender is not the owner.
    function _checkOwner() internal view virtual {
        /// @solidity memory-safe-assembly
        assembly {
            // If the caller is not the stored owner, revert.
            if iszero(eq(caller(), sload(not(_OWNER_SLOT_NOT)))) {
                mstore(0x00, 0x82b42900) // `Unauthorized()`.
                revert(0x1c, 0x04)
            }
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                  PUBLIC UPDATE FUNCTIONS                   */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Allows the owner to transfer the ownership to `newOwner`.
    function transferOwnership(address newOwner) public payable virtual onlyOwner {
        /// @solidity memory-safe-assembly
        assembly {
            if iszero(shl(96, newOwner)) {
                mstore(0x00, 0x7448fbae) // `NewOwnerIsZeroAddress()`.
                revert(0x1c, 0x04)
            }
        }
        _setOwner(newOwner);
    }

    /// @dev Allows the owner to renounce their ownership.
    function renounceOwnership() public payable virtual onlyOwner {
        _setOwner(address(0));
    }

    /// @dev Request a two-step ownership handover to the caller.
    /// The request will be automatically expire in 48 hours (172800 seconds) by default.
    function requestOwnershipHandover() public payable virtual {
        unchecked {
            uint256 expires = block.timestamp + ownershipHandoverValidFor();
            /// @solidity memory-safe-assembly
            assembly {
                // Compute and set the handover slot to `expires`.
                mstore(0x0c, _HANDOVER_SLOT_SEED)
                mstore(0x00, caller())
                sstore(keccak256(0x0c, 0x20), expires)
                // Emit the {OwnershipHandoverRequested} event.
                log2(0, 0, _OWNERSHIP_HANDOVER_REQUESTED_EVENT_SIGNATURE, caller())
            }
        }
    }

    /// @dev Cancels the two-step ownership handover to the caller, if any.
    function cancelOwnershipHandover() public payable virtual {
        /// @solidity memory-safe-assembly
        assembly {
            // Compute and set the handover slot to 0.
            mstore(0x0c, _HANDOVER_SLOT_SEED)
            mstore(0x00, caller())
            sstore(keccak256(0x0c, 0x20), 0)
            // Emit the {OwnershipHandoverCanceled} event.
            log2(0, 0, _OWNERSHIP_HANDOVER_CANCELED_EVENT_SIGNATURE, caller())
        }
    }

    /// @dev Allows the owner to complete the two-step ownership handover to `pendingOwner`.
    /// Reverts if there is no existing ownership handover requested by `pendingOwner`.
    function completeOwnershipHandover(address pendingOwner) public payable virtual onlyOwner {
        /// @solidity memory-safe-assembly
        assembly {
            // Compute and set the handover slot to 0.
            mstore(0x0c, _HANDOVER_SLOT_SEED)
            mstore(0x00, pendingOwner)
            let handoverSlot := keccak256(0x0c, 0x20)
            // If the handover does not exist, or has expired.
            if gt(timestamp(), sload(handoverSlot)) {
                mstore(0x00, 0x6f5e8818) // `NoHandoverRequest()`.
                revert(0x1c, 0x04)
            }
            // Set the handover slot to 0.
            sstore(handoverSlot, 0)
        }
        _setOwner(pendingOwner);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                   PUBLIC READ FUNCTIONS                    */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the owner of the contract.
    function owner() public view virtual returns (address result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := sload(not(_OWNER_SLOT_NOT))
        }
    }

    /// @dev Returns the expiry timestamp for the two-step ownership handover to `pendingOwner`.
    function ownershipHandoverExpiresAt(address pendingOwner)
        public
        view
        virtual
        returns (uint256 result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            // Compute the handover slot.
            mstore(0x0c, _HANDOVER_SLOT_SEED)
            mstore(0x00, pendingOwner)
            // Load the handover slot.
            result := sload(keccak256(0x0c, 0x20))
        }
    }

    /// @dev Returns how long a two-step ownership handover is valid for in seconds.
    function ownershipHandoverValidFor() public view virtual returns (uint64) {
        return 48 * 3600;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         MODIFIERS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Marks a function as only callable by the owner.
    modifier onlyOwner() virtual {
        _checkOwner();
        _;
    }
}
// File: contracts/ERC20.sol


/*

SnCCnCCnCCCnCCCnnSCCSCCCSCSSCSC8bC8SC8bCb8SCCb8SCS99w888S99w8w88dwb88w$8b889S$q8qq89qddq$w$q09qq$qqqqq$$0qqqq0$8$q$8d8q8$988dwSw8888$$$dw$d8d9dq$w9dCI
C8CCCSCCCnCCC8CSSSC8bw8CCSCb8S9CC8b9dbS$CC$Sb8d88$SSCIu]2zzc7stti+++++}+}t?i?jjj1vvczz2xnC$00qqqqq00qq0$00q$q0$0qqq$q09$q$dwwbbqq$d$$999$$$$q89q$$8wbS
CnC8bCbSCSSCbbSCnw8CS8C89SdS8w8q89w9Sd$89$dnxzct}+"|__~~~~~~~~~~~~~~~_________________~~___"+t7leuCd0q000000000d0q0qq00dqqqq$0qq$99q0$qq$qq$q$9$88dduc
CSCbCCCCCCCSCbbC8SbbC9bC88CSwSw8Sw8$$8buz7+<_~~~~~^^^^^^^^^^^^^^^^^^~~~_______________~~____~_~___|"szuSqp0000000qqq00qqqq0d0qdqqqq0qqqqq000q$$0qqq8$8
8CCd88SwC98S9wdbS9dC99b9S$$w89$w9qq8ar+|_~~^^^^^\\\\\\\\\\\\\^^^^^^^^^~~~~~~~~~~~~~~~~~~~______________|+s2nq00q0000000q00q00$0q00q00000q00q$q$qq8qd88
8n8bCCCSS88b889SC88SSw8S$w8w$$w$dSCc|~^^^^\\\\\\\\\\\\\\\\\\\\\^^^^^^^^^^~~~~~~~~~~~~~~~~~~~________________"izxC00qp0p00p0000000000000q$qq00$qqw$qwne
SCCwSCSSbC88bq$bwd88898S9w9dd8ddxr"^\\\\\\\\\\\\\^^^\\\\\\\\\\\\\^^^^~~~~~~~~~~________~~~~_______________~_____|"tzxq00000000q0p0q000000p0qqq000qq0bn
999dCSb88dd880qw8$89qq$d$9q$8qxt^\\\\\\\\\\\\^^^^^^^^^^^^^~~~~~~_____________________________|||||||____________~__~_"lC0p0000000p0p0000000q$q000qqq$d
SCb9bbbS88n8S9w8ww9d8$$wdq8S2}~'\\\\\\\\\\^^^^^^^^^^~~________||||||_________________________|||||||||_________________|}znqp000p0000000q000pq00$00qC3
8$b88S8q$8w88wq$dqq8q$d0Suv|\\\\\^^^^^^^~~~~~________||||||||||||||||___|_______||||||||||____|||||||||||___||__||<<<<||___>ted0000h0pp0k0000p00h00q00
$ddqd9bCq$d$$8qdq9qq89wa}_\\\^^^^^~~~~____________|||||<<<<<|<<<<<<<<>>""><|||||||||||||>"<_____||<<<<<<>><<>>>|__|<>>>>><||__>cCppUphkkFk0ppp0p0p0q00
w8dS$w8$$qq00q00$00$8ut_^\^^^^^~~~____________|||||||<<<<<<<<<<<<<>>""""">|_||<<<||||||<>"">_____|<>>>>>>"""""">>|__|<><<|||<<|_|1Chppppppp0ph0000q0C2
d$qd8$qqq8qq$q$0q0$82<^^^~~~~~____________||||||||||<<<>><<<<<>>>>""""<|<<|_|||<<|__||<>>"++"_____|>""""">"""""">><_~_<>>>|__|<><_|c0kZkUkkhh0ppkk00pp
08dd$qq0qw00qq009qbz>_~~~~~____________|<<<||||||<<<<<>>>><<>><>"""">||||||||<<<||__|<<>>"+++"|_~__>>"""">"""""">>><_~_<>>><__|<<<__lkZFUFh0ppppkpq0pp
$bqqqq$0qq0qq000dSe"______~___||____||<<><|||_|<<<<>>>>>>>>><>>""">||_|||||||<|<|___|||<>"++++"__~_<>"""""""""""">>>>|_|>>>><|_|<<<|_xUkZUpZZpp00pp0C2
qq$$w$q0q90000p$be+__________|<|___<""><<|____|<<<>>>>>>>>>>>>""">|__||||||||<<<|______|<>+++++>___>"""""""""""""">>>>__>>>>><__|<><|+0FkgkpZkphUpp0kh
q000000000000$0pwi_~____~~_|<<<|__<""""><_____<>>>>><>>>>>>><>"">|_|_|<|_||||<<<|______|<>"++++"___>""""""""""""""">>>|_<<>>>>|_|<>><|lZgUFZhhppUkppkg
0q$qq$0p0q0p0pp0x|_____~_|<>>"<__<"++"><|__~~|<>>>><>>>>>>>>>"""||||<>|||<<||<<|________<vx+++++<__>""""""""""""""">>><|<>>>>><__<>>>||bggFpFUpZkZp0qx
q0000000000000001_____~_|>""++<__>"+"><<|__~_<<>>>><<>>>>>><>"">|_||>>|||><||<||________|"0+++++>__>""""""""""""""">>>><><>>>>>|_|<><|_2FgAgFFZZgFFkZp
0p000p0p0qkpp0kn"______|>"++++|~_""""<|<|__~_<>>>>>>>>>>>><>"""|__|<"|||>">_|<|||______|>"kl+++""|_>"""""""""""""""">>>>>>>>>>>|_|<<<|_tkAFkZFFkUUkkgg
0$p0qp000pppp0pl____~_<<"++++"_~_""">|_<<_~~_<>>>>>>>>>>>>>>""<|__|>>|||"">|||<||______|""03++"""||>"""""""""""""""">>>>>>>>>><__|<<<|_+0AAgAFFFggFU0n
pkp0p00h00kppp0+___~_<>>"++++>~~|"""<|_<<|~~_<<>>>>>>>>>>>>"""||||t+<||<"""||<<<|______<""pI+i"""<|>"""""""""""""""">>>>>>>>>>|__<><<__jgAgAgFAgggFgg0
phhhppkpkpZkp0n>__~_<>>"++++"|~~_"">|__<<|~~_<<<>>>>>>>>>>>""<||_"I"<||>""""<<<<<||||||"""PS+c"""">>"""""""""""""""">>>>>">>><__|<>><|_xAAAAAAFgZAgZgP
0ppphkkppphZh0z__~_<>>"+++++>_~~|""<__|<>|_~_|<<>>>>>>>>>>"""|__|zC><|<""""++++}rllzllcs+vmS2u}uCSbb8w$qq$$wSnalsi+"">>>"""">|||<<>><__0AAAAAAgggggggh
kppkh0khkhZhp$?_~~|>>"++++++|_~~|""|__|<>>|~__<>>>>>>>>>>>"+"|_|+0n+tcxCdpFAPGGOOmmmmmmmgAmPmPPmmmmmmmmmmmmmmmmmOOPAh8u2cj++""><>>>><|lAAPAAAAAAAAAgA0
FZFFZkUUZkUZF8+__|<>"++++++"__~_|>>|_~_<>">_~_|<>>>>>>>>>>"">|<+IGAgOOmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmPk8I3zzz2aICqAPApnc"">>>>|lAPPPPAPPAAAAAgFA
k0kZZkkghFgkUk?__<<>"++++++>__~~|>>__~_<>""_~__<>>>>>><<>"+t2n0AGmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmAu}\`,^_|<>>|_'`:+IPOPCt">"?aUPPAPPAAAAAAAAggg
UZUUphUUgZZFgkz_|>>"+++++++<__~~_||_~~_<>""^^~_|>>>><>>"+lqGmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmI:`"zls+""+++?zCpx<`<kOG$i20PPPPPPPPPPAAAAAAAgg
kkhFFkggFZFFg01_<>>"++++++"____~~___~_|<>"+|\~__<>>>>>+e0OmmmmmmPZ$Cnu]3]xnC8PmmmmmmmmmmmmmmmmmmmmmmmmmZxel+"___~^:,,,_uPC,`tPOGAPGGPPPPPPPPAPPPAAAAAA
k0UFpZFkggZAgn><>>>"++++++>_____~~~~_|<>>"++"<|||>>""v0Ommmmpxt<:``,\|"""|^'^nmmmmmmmmmmmmmmmmmmmmmmmOOOGIac' ', `,,` `lPP3>+AOGGPPPPPPPPPPAPPPPAAPAAP
kppgUpFFUkkFq+_>>>"+++++++|~~____~~_|<>>>>+}2$082j""zPmmA8z"`\+vzllzzzc7jti}lAmmmmmmmmmmmmmmmmmmmmmmOOOOOp+  zMX+`,'` '`zPGPPGOGPPPPPGPPPPPPPPPPAAPAAA
FFggkZFgFUgh7_<>>>"++++++|_~~___~_|<<>>>>"+1gmmmmmA0gPu+:`~1Sbz+>+?c2I80FAgp0PmmmmmmmmmmmmXXXXXmmmOGGGOOg\ ` 0HHZ``'` "_`xGGGGOGPPPGGPGGPPPPPPPPPPPPPP
FpZggUAgkgkz_|>>>>"+++++"____~__|<>>>>>"+}?nmmmmmmFz"`^cnFO0i71?"^`  ```->7SPmmmmmmmmmmmmXXXXXXXmOGPGGOG} ` `>nn"`,:` +|>_9GGGGGPPPPPGPPPPPGPPPPAPPPPP
gggggpgAggn|_<>>>"+++++"_~____|<>>>>>>>+72$OmmmmO2'`>aPmmmmA2>``^}l^ ```   ,+0mmmmmmmmmmmXXXXXXXmGPPPGO0,-_ ,-,,,'',  t^000GGGGGOGGGGGPPPPPGPPPPPPPPPA
AUgAgFAAF0}~_<>>>"++++"____|<<<>>"+szxn0APOmmmmmI,,2GmmmmAl\  ,[email protected] ,'',``  \2PmXmmmmmmmXXXXXWXXOPPPGOe "i `:'''''` ,t,X&PGGGGGPPGPPGGGPPGPPPPGPPGPPP
gUpkUFAAFx_~|<>>>"+++"___|<>"}c2nqAPPPPGGOmmmmmG+`}OmmmPe\ `^```,_\``''''',   `ymmmmmmmmmXXXXXXXmOPPGOmy +z``,'''',` +}\DXGGGGOGGGGGPGPGGPGPPPGPPPPPPA
Apb89hAAAc__<<>>>"++}tt1eC$0gPPPGGGGGOOOOOmmmmmmA0AmmmA}`` ^2\`-:-:'''''''- `` <PmmmmmmmmXXXXXXXmOPPGOm0`+2+``-'':` ^2<1MGPGGGGOPGGOGGGGGGGPGPGGPPGPPP
Z8exC0PAgt~_<>>>>+a0UPPPPPPGGGOOOOOOOOOOmmmmmmmmmmmmmm3,+C^'u7``:'''''''''- '?``pmmmmmmmmXXXXXXXmOPGGOOP""za}``````1"|~gmPPPGGGOGGPGPPGPPPPPPGPPPPPPPP
$azenpAAk+~_<><"[email protected]`lI?``-'''''''', "z| xmmmmmmmmmXXXXXWmOPGGOOmC\+zec"^^<|ez,xWPPPGGGGGGPGGPPGPPPPPPPPPPPPPPp
2zczIn$$C+__<>>yPPPPPGGOOmmmmmmmmmmmmmmmmmmmmmmOmmmmmmgGDHF,_znz^``,,--,,` `<i|`CmmmmmmmmmmmXXXXmOGPPGGOmZ27}tl23z?_\ImGPPGGGGPOPGGPPPPPPPPPPPPPPPPPPP
+ivleuIIa+__<>>+9PPPPPGGOmmmmmmmmmmmmmmmmmmmmmmOmmmmmmmmXDB9`<zIuj\`    ``2p:~`"PmmmmmmmOmmmmmmmmOOGPPGGOmmmAnl}">^"qPPPPGGGOGPPPPPPPPPPPPPPPPPPAPPAPA
""+}tlzze}_|<<>>tdPPPPPGGGOOmmmmmmmmmmmmmmmmmmmmmmmmmmmmmXMBu^_t2axelj?r7:7g'`\qmmmmmmmmOOmmmmmOOGOOOPPGGOOOOOOGA8ztinPPGGGOOPPAAAAAAAAAAAAAPAAAAAAAk8
>""++"+slt||<<<"+"sqPPPPPPGGOOmmmmmmmmmmmmmmmmmOOOmmmmmmmmmWQXl'\"c2xIIx2+\``+gmmmmmmmmmmmmmmmmmmmmmXOPPPPGPPPPPPPPPPPPPGGOOP00q0qqq8qq0p00kpkFhgAAAAA
>>"""""+}}"|<><""|_|z0PPPPPPGGGOOOmmmmmmmmmmmmmOOOOmmmmmmmmmX&MXCt<_>+t}+_,<uOmmmmmmmmmmmmmmmmXW&&@&XmGPPPPPPPPPPPPPPPPGGOOACunnInIuunnnCCnICS8$0gAAAg
~~_">|">"+"<><<""_____ixFPPPPPPPGmXmGOOOOOmmmmmOOOOmmmmmmmmmmmmXk}~````_+28OmmmmmmmmmmmmmmmmmmXW&@@@&XmPPPPPPPPPPPPPPPPPGGFauInnnxnnnCnnnnnnnC8$pFggU9
~~_|<_>>""">>><""_~___~\|1x9APPPOMRWPPPPGGGGGGGGGOOOOmmmmmmmmmmmmAa]n0POmmmmmmmmmmmmmmmmmmmmmmmmXXW&&WXmGGPPPPPPPPPPPPPGGFzICn90$wwCCC8nnCCnC$90FhppUk
*/
pragma solidity ^0.8.4;

/// @notice Simple ERC20 + EIP-2612 implementation.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol)
abstract contract ERC20 {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The total supply has overflowed.
    error TotalSupplyOverflow();

    /// @dev The allowance has overflowed.
    error AllowanceOverflow();

    /// @dev The allowance has underflowed.
    error AllowanceUnderflow();

    /// @dev Insufficient balance.
    error InsufficientBalance();

    /// @dev Insufficient allowance.
    error InsufficientAllowance();

    /// @dev The permit is invalid.
    error InvalidPermit();

    /// @dev The permit has expired.
    error PermitExpired();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                           EVENTS                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Emitted when `amount` tokens is transferred from `from` to `to`.
    event Transfer(address indexed from, address indexed to, uint256 amount);

    /// @dev Emitted when `amount` tokens is approved by `owner` to be used by `spender`.
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /// @dev `keccak256(bytes("Transfer(address,address,uint256)"))`.
    uint256 private constant _TRANSFER_EVENT_SIGNATURE =
        0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef;

    /// @dev `keccak256(bytes("Approval(address,address,uint256)"))`.
    uint256 private constant _APPROVAL_EVENT_SIGNATURE =
        0x8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          STORAGE                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The storage slot for the total supply.
    uint256 private constant _TOTAL_SUPPLY_SLOT = 0x05345cdf77eb68f44c;

    /// @dev The balance slot of `owner` is given by:
    /// ```
    ///     mstore(0x0c, _BALANCE_SLOT_SEED)
    ///     mstore(0x00, owner)
    ///     let balanceSlot := keccak256(0x0c, 0x20)
    /// ```
    uint256 private constant _BALANCE_SLOT_SEED = 0x87a211a2;

    /// @dev The allowance slot of (`owner`, `spender`) is given by:
    /// ```
    ///     mstore(0x20, spender)
    ///     mstore(0x0c, _ALLOWANCE_SLOT_SEED)
    ///     mstore(0x00, owner)
    ///     let allowanceSlot := keccak256(0x0c, 0x34)
    /// ```
    uint256 private constant _ALLOWANCE_SLOT_SEED = 0x7f5e9f20;

    /// @dev The nonce slot of `owner` is given by:
    /// ```
    ///     mstore(0x0c, _NONCES_SLOT_SEED)
    ///     mstore(0x00, owner)
    ///     let nonceSlot := keccak256(0x0c, 0x20)
    /// ```
    uint256 private constant _NONCES_SLOT_SEED = 0x38377508;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       ERC20 METADATA                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the name of the token.
    function name() public view virtual returns (string memory);

    /// @dev Returns the symbol of the token.
    function symbol() public view virtual returns (string memory);

    /// @dev Returns the decimals places of the token.
    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                           ERC20                            */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the amount of tokens in existence.
    function totalSupply() public view virtual returns (uint256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := sload(_TOTAL_SUPPLY_SLOT)
        }
    }

    /// @dev Returns the amount of tokens owned by `owner`.
    function balanceOf(address owner) public view virtual returns (uint256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x0c, _BALANCE_SLOT_SEED)
            mstore(0x00, owner)
            result := sload(keccak256(0x0c, 0x20))
        }
    }

    /// @dev Returns the amount of tokens that `spender` can spend on behalf of `owner`.
    function allowance(address owner, address spender)
        public
        view
        virtual
        returns (uint256 result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x20, spender)
            mstore(0x0c, _ALLOWANCE_SLOT_SEED)
            mstore(0x00, owner)
            result := sload(keccak256(0x0c, 0x34))
        }
    }

    /// @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
    ///
    /// Emits a {Approval} event.
    function approve(address spender, uint256 amount) public virtual returns (bool) {
        /// @solidity memory-safe-assembly
        assembly {
            // Compute the allowance slot and store the amount.
            mstore(0x20, spender)
            mstore(0x0c, _ALLOWANCE_SLOT_SEED)
            mstore(0x00, caller())
            sstore(keccak256(0x0c, 0x34), amount)
            // Emit the {Approval} event.
            mstore(0x00, amount)
            log3(0x00, 0x20, _APPROVAL_EVENT_SIGNATURE, caller(), shr(96, mload(0x2c)))
        }
        return true;
    }

    /// @dev Atomically increases the allowance granted to `spender` by the caller.
    ///
    /// Emits a {Approval} event.
    function increaseAllowance(address spender, uint256 difference) public virtual returns (bool) {
        /// @solidity memory-safe-assembly
        assembly {
            // Compute the allowance slot and load its value.
            mstore(0x20, spender)
            mstore(0x0c, _ALLOWANCE_SLOT_SEED)
            mstore(0x00, caller())
            let allowanceSlot := keccak256(0x0c, 0x34)
            let allowanceBefore := sload(allowanceSlot)
            // Add to the allowance.
            let allowanceAfter := add(allowanceBefore, difference)
            // Revert upon overflow.
            if lt(allowanceAfter, allowanceBefore) {
                mstore(0x00, 0xf9067066) // `AllowanceOverflow()`.
                revert(0x1c, 0x04)
            }
            // Store the updated allowance.
            sstore(allowanceSlot, allowanceAfter)
            // Emit the {Approval} event.
            mstore(0x00, allowanceAfter)
            log3(0x00, 0x20, _APPROVAL_EVENT_SIGNATURE, caller(), shr(96, mload(0x2c)))
        }
        return true;
    }

    /// @dev Atomically decreases the allowance granted to `spender` by the caller.
    ///
    /// Emits a {Approval} event.
    function decreaseAllowance(address spender, uint256 difference) public virtual returns (bool) {
        /// @solidity memory-safe-assembly
        assembly {
            // Compute the allowance slot and load its value.
            mstore(0x20, spender)
            mstore(0x0c, _ALLOWANCE_SLOT_SEED)
            mstore(0x00, caller())
            let allowanceSlot := keccak256(0x0c, 0x34)
            let allowanceBefore := sload(allowanceSlot)
            // Revert if will underflow.
            if lt(allowanceBefore, difference) {
                mstore(0x00, 0x8301ab38) // `AllowanceUnderflow()`.
                revert(0x1c, 0x04)
            }
            // Subtract and store the updated allowance.
            let allowanceAfter := sub(allowanceBefore, difference)
            sstore(allowanceSlot, allowanceAfter)
            // Emit the {Approval} event.
            mstore(0x00, allowanceAfter)
            log3(0x00, 0x20, _APPROVAL_EVENT_SIGNATURE, caller(), shr(96, mload(0x2c)))
        }
        return true;
    }

    /// @dev Transfer `amount` tokens from the caller to `to`.
    ///
    /// Requirements:
    /// - `from` must at least have `amount`.
    ///
    /// Emits a {Transfer} event.
    function transfer(address to, uint256 amount) public virtual returns (bool) {
        _beforeTokenTransfer(msg.sender, to, amount);
        /// @solidity memory-safe-assembly
        assembly {
            // Compute the balance slot and load its value.
            mstore(0x0c, _BALANCE_SLOT_SEED)
            mstore(0x00, caller())
            let fromBalanceSlot := keccak256(0x0c, 0x20)
            let fromBalance := sload(fromBalanceSlot)
            // Revert if insufficient balance.
            if gt(amount, fromBalance) {
                mstore(0x00, 0xf4d678b8) // `InsufficientBalance()`.
                revert(0x1c, 0x04)
            }
            // Subtract and store the updated balance.
            sstore(fromBalanceSlot, sub(fromBalance, amount))
            // Compute the balance slot of `to`.
            mstore(0x00, to)
            let toBalanceSlot := keccak256(0x0c, 0x20)
            // Add and store the updated balance of `to`.
            // Will not overflow because the sum of all user balances
            // cannot exceed the maximum uint256 value.
            sstore(toBalanceSlot, add(sload(toBalanceSlot), amount))
            // Emit the {Transfer} event.
            mstore(0x20, amount)
            log3(0x20, 0x20, _TRANSFER_EVENT_SIGNATURE, caller(), shr(96, mload(0x0c)))
        }
        _afterTokenTransfer(msg.sender, to, amount);
        return true;
    }

    /// @dev Transfers `amount` tokens from `from` to `to`.
    ///
    /// Note: does not update the allowance if it is the maximum uint256 value.
    ///
    /// Requirements:
    /// - `from` must at least have `amount`.
    /// - The caller must have at least `amount` of allowance to transfer the tokens of `from`.
    ///
    /// Emits a {Transfer} event.
    function transferFrom(address from, address to, uint256 amount) public virtual returns (bool) {
        _beforeTokenTransfer(from, to, amount);
        /// @solidity memory-safe-assembly
        assembly {
            let from_ := shl(96, from)
            // Compute the allowance slot and load its value.
            mstore(0x20, caller())
            mstore(0x0c, or(from_, _ALLOWANCE_SLOT_SEED))
            let allowanceSlot := keccak256(0x0c, 0x34)
            let allowance_ := sload(allowanceSlot)
            // If the allowance is not the maximum uint256 value.
            if iszero(eq(allowance_, not(0))) {
                // Revert if the amount to be transferred exceeds the allowance.
                if gt(amount, allowance_) {
                    mstore(0x00, 0x13be252b) // `InsufficientAllowance()`.
                    revert(0x1c, 0x04)
                }
                // Subtract and store the updated allowance.
                sstore(allowanceSlot, sub(allowance_, amount))
            }
            // Compute the balance slot and load its value.
            mstore(0x0c, or(from_, _BALANCE_SLOT_SEED))
            let fromBalanceSlot := keccak256(0x0c, 0x20)
            let fromBalance := sload(fromBalanceSlot)
            // Revert if insufficient balance.
            if gt(amount, fromBalance) {
                mstore(0x00, 0xf4d678b8) // `InsufficientBalance()`.
                revert(0x1c, 0x04)
            }
            // Subtract and store the updated balance.
            sstore(fromBalanceSlot, sub(fromBalance, amount))
            // Compute the balance slot of `to`.
            mstore(0x00, to)
            let toBalanceSlot := keccak256(0x0c, 0x20)
            // Add and store the updated balance of `to`.
            // Will not overflow because the sum of all user balances
            // cannot exceed the maximum uint256 value.
            sstore(toBalanceSlot, add(sload(toBalanceSlot), amount))
            // Emit the {Transfer} event.
            mstore(0x20, amount)
            log3(0x20, 0x20, _TRANSFER_EVENT_SIGNATURE, shr(96, from_), shr(96, mload(0x0c)))
        }
        _afterTokenTransfer(from, to, amount);
        return true;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          EIP-2612                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the current nonce for `owner`.
    /// This value is used to compute the signature for EIP-2612 permit.
    function nonces(address owner) public view virtual returns (uint256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            // Compute the nonce slot and load its value.
            mstore(0x0c, _NONCES_SLOT_SEED)
            mstore(0x00, owner)
            result := sload(keccak256(0x0c, 0x20))
        }
    }

    /// @dev Sets `value` as the allowance of `spender` over the tokens of `owner`,
    /// authorized by a signed approval by `owner`.
    ///
    /// Emits a {Approval} event.
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        bytes32 domainSeparator = DOMAIN_SEPARATOR();
        /// @solidity memory-safe-assembly
        assembly {
            // Grab the free memory pointer.
            let m := mload(0x40)
            // Revert if the block timestamp greater than `deadline`.
            if gt(timestamp(), deadline) {
                mstore(0x00, 0x1a15a3cc) // `PermitExpired()`.
                revert(0x1c, 0x04)
            }
            // Clean the upper 96 bits.
            owner := shr(96, shl(96, owner))
            spender := shr(96, shl(96, spender))
            // Compute the nonce slot and load its value.
            mstore(0x0c, _NONCES_SLOT_SEED)
            mstore(0x00, owner)
            let nonceSlot := keccak256(0x0c, 0x20)
            let nonceValue := sload(nonceSlot)
            // Increment and store the updated nonce.
            sstore(nonceSlot, add(nonceValue, 1))
            // Prepare the inner hash.
            // `keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)")`.
            // forgefmt: disable-next-item
            mstore(m, 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9)
            mstore(add(m, 0x20), owner)
            mstore(add(m, 0x40), spender)
            mstore(add(m, 0x60), value)
            mstore(add(m, 0x80), nonceValue)
            mstore(add(m, 0xa0), deadline)
            // Prepare the outer hash.
            mstore(0, 0x1901)
            mstore(0x20, domainSeparator)
            mstore(0x40, keccak256(m, 0xc0))
            // Prepare the ecrecover calldata.
            mstore(0, keccak256(0x1e, 0x42))
            mstore(0x20, and(0xff, v))
            mstore(0x40, r)
            mstore(0x60, s)
            pop(staticcall(gas(), 1, 0, 0x80, 0x20, 0x20))
            // If the ecrecover fails, the returndatasize will be 0x00,
            // `owner` will be be checked if it equals the hash at 0x00,
            // which evaluates to false (i.e. 0), and we will revert.
            // If the ecrecover succeeds, the returndatasize will be 0x20,
            // `owner` will be compared against the returned address at 0x20.
            if iszero(eq(mload(returndatasize()), owner)) {
                mstore(0x00, 0xddafbaef) // `InvalidPermit()`.
                revert(0x1c, 0x04)
            }
            // Compute the allowance slot and store the value.
            // The `owner` is already at slot 0x20.
            mstore(0x40, or(shl(160, _ALLOWANCE_SLOT_SEED), spender))
            sstore(keccak256(0x2c, 0x34), value)
            // Emit the {Approval} event.
            log3(add(m, 0x60), 0x20, _APPROVAL_EVENT_SIGNATURE, owner, spender)
            mstore(0x40, m) // Restore the free memory pointer.
            mstore(0x60, 0) // Restore the zero pointer.
        }
    }

    /// @dev Returns the EIP-2612 domains separator.
    function DOMAIN_SEPARATOR() public view virtual returns (bytes32 result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(0x40) // Grab the free memory pointer.
        }
        //  We simply calculate it on-the-fly to allow for cases where the `name` may change.
        bytes32 nameHash = keccak256(bytes(name()));
        /// @solidity memory-safe-assembly
        assembly {
            let m := result
            // `keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")`.
            // forgefmt: disable-next-item
            mstore(m, 0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f)
            mstore(add(m, 0x20), nameHash)
            // `keccak256("1")`.
            // forgefmt: disable-next-item
            mstore(add(m, 0x40), 0xc89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc6)
            mstore(add(m, 0x60), chainid())
            mstore(add(m, 0x80), address())
            result := keccak256(m, 0xa0)
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                  INTERNAL MINT FUNCTIONS                   */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Mints `amount` tokens to `to`, increasing the total supply.
    ///
    /// Emits a {Transfer} event.
    function _mint(address to, uint256 amount) internal virtual {
        _beforeTokenTransfer(address(0), to, amount);
        /// @solidity memory-safe-assembly
        assembly {
            let totalSupplyBefore := sload(_TOTAL_SUPPLY_SLOT)
            let totalSupplyAfter := add(totalSupplyBefore, amount)
            // Revert if the total supply overflows.
            if lt(totalSupplyAfter, totalSupplyBefore) {
                mstore(0x00, 0xe5cfe957) // `TotalSupplyOverflow()`.
                revert(0x1c, 0x04)
            }
            // Store the updated total supply.
            sstore(_TOTAL_SUPPLY_SLOT, totalSupplyAfter)
            // Compute the balance slot and load its value.
            mstore(0x0c, _BALANCE_SLOT_SEED)
            mstore(0x00, to)
            let toBalanceSlot := keccak256(0x0c, 0x20)
            // Add and store the updated balance.
            sstore(toBalanceSlot, add(sload(toBalanceSlot), amount))
            // Emit the {Transfer} event.
            mstore(0x20, amount)
            log3(0x20, 0x20, _TRANSFER_EVENT_SIGNATURE, 0, shr(96, mload(0x0c)))
        }
        _afterTokenTransfer(address(0), to, amount);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                  INTERNAL BURN FUNCTIONS                   */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Burns `amount` tokens from `from`, reducing the total supply.
    ///
    /// Emits a {Transfer} event.
    function _burn(address from, uint256 amount) internal virtual {
        _beforeTokenTransfer(from, address(0), amount);
        /// @solidity memory-safe-assembly
        assembly {
            // Compute the balance slot and load its value.
            mstore(0x0c, _BALANCE_SLOT_SEED)
            mstore(0x00, from)
            let fromBalanceSlot := keccak256(0x0c, 0x20)
            let fromBalance := sload(fromBalanceSlot)
            // Revert if insufficient balance.
            if gt(amount, fromBalance) {
                mstore(0x00, 0xf4d678b8) // `InsufficientBalance()`.
                revert(0x1c, 0x04)
            }
            // Subtract and store the updated balance.
            sstore(fromBalanceSlot, sub(fromBalance, amount))
            // Subtract and store the updated total supply.
            sstore(_TOTAL_SUPPLY_SLOT, sub(sload(_TOTAL_SUPPLY_SLOT), amount))
            // Emit the {Transfer} event.
            mstore(0x00, amount)
            log3(0x00, 0x20, _TRANSFER_EVENT_SIGNATURE, shr(96, shl(96, from)), 0)
        }
        _afterTokenTransfer(from, address(0), amount);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                INTERNAL TRANSFER FUNCTIONS                 */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Moves `amount` of tokens from `from` to `to`.
    function _transfer(address from, address to, uint256 amount) internal virtual {
        _beforeTokenTransfer(from, to, amount);
        /// @solidity memory-safe-assembly
        assembly {
            let from_ := shl(96, from)
            // Compute the balance slot and load its value.
            mstore(0x0c, or(from_, _BALANCE_SLOT_SEED))
            let fromBalanceSlot := keccak256(0x0c, 0x20)
            let fromBalance := sload(fromBalanceSlot)
            // Revert if insufficient balance.
            if gt(amount, fromBalance) {
                mstore(0x00, 0xf4d678b8) // `InsufficientBalance()`.
                revert(0x1c, 0x04)
            }
            // Subtract and store the updated balance.
            sstore(fromBalanceSlot, sub(fromBalance, amount))
            // Compute the balance slot of `to`.
            mstore(0x00, to)
            let toBalanceSlot := keccak256(0x0c, 0x20)
            // Add and store the updated balance of `to`.
            // Will not overflow because the sum of all user balances
            // cannot exceed the maximum uint256 value.
            sstore(toBalanceSlot, add(sload(toBalanceSlot), amount))
            // Emit the {Transfer} event.
            mstore(0x20, amount)
            log3(0x20, 0x20, _TRANSFER_EVENT_SIGNATURE, shr(96, from_), shr(96, mload(0x0c)))
        }
        _afterTokenTransfer(from, to, amount);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                INTERNAL ALLOWANCE FUNCTIONS                */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Updates the allowance of `owner` for `spender` based on spent `amount`.
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        /// @solidity memory-safe-assembly
        assembly {
            // Compute the allowance slot and load its value.
            mstore(0x20, spender)
            mstore(0x0c, _ALLOWANCE_SLOT_SEED)
            mstore(0x00, owner)
            let allowanceSlot := keccak256(0x0c, 0x34)
            let allowance_ := sload(allowanceSlot)
            // If the allowance is not the maximum uint256 value.
            if iszero(eq(allowance_, not(0))) {
                // Revert if the amount to be transferred exceeds the allowance.
                if gt(amount, allowance_) {
                    mstore(0x00, 0x13be252b) // `InsufficientAllowance()`.
                    revert(0x1c, 0x04)
                }
                // Subtract and store the updated allowance.
                sstore(allowanceSlot, sub(allowance_, amount))
            }
        }
    }

    /// @dev Sets `amount` as the allowance of `spender` over the tokens of `owner`.
    ///
    /// Emits a {Approval} event.
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        /// @solidity memory-safe-assembly
        assembly {
            let owner_ := shl(96, owner)
            // Compute the allowance slot and store the amount.
            mstore(0x20, spender)
            mstore(0x0c, or(owner_, _ALLOWANCE_SLOT_SEED))
            sstore(keccak256(0x0c, 0x34), amount)
            // Emit the {Approval} event.
            mstore(0x00, amount)
            log3(0x00, 0x20, _APPROVAL_EVENT_SIGNATURE, shr(96, owner_), shr(96, mload(0x2c)))
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                     HOOKS TO OVERRIDE                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Hook that is called before any transfer of tokens.
    /// This includes minting and burning.
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    /// @dev Hook that is called after any transfer of tokens.
    /// This includes minting and burning.
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}
// File: contracts/Simp.sol

pragma solidity ^0.8.19;




contract Simp is ERC20, Ownable {
    
    address public immutable UNISWAP_V2_FACTORY_ADDRESS=0xc35DADB65012eC5796536bD9864eD8773aBc74C4;
    address public immutable USDC=0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;    
    address public uniswapV2Pair;    

    mapping(address => bool) public farmContracts;
    constructor() {
        uniswapV2Pair = IUniswapV2Factory(UNISWAP_V2_FACTORY_ADDRESS).createPair(
            address(this),
            USDC
        );        
        _initializeOwner(msg.sender);
        _mint(msg.sender, 69_000_000_000_000 * 1e18);
        
    }

    modifier onlyFarm() {
        require(
           farmContracts[msg.sender],
            "Only farm contract can call this function"
        );
        _;
    }

    function removeFutureContract(address _farmContract) public onlyOwner {
        delete farmContracts[_farmContract];
    }

    function addFarmContract(address _farmContract) public onlyOwner {
        farmContracts[_farmContract] = true;
    }

    function farmMint(address recipient, uint256 amount) external onlyFarm {
        _mint(recipient, amount);
    }

    function farmBurn(address recipient, uint256 amount) external onlyFarm {
        _burn(recipient, amount);
    }

    function name() public pure override returns (string memory) {
        return "Simp";
    }

    function symbol() public pure override returns (string memory) {
        return "SIMP";
    }

    function decimals() public pure override returns (uint8) {
        return 18;
    }
   
}

// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// File: @openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol


// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;




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

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: contracts/simpFarm.sol


/*
Website: egirl.money
Twitter: @egirl_money
Telegram: t.me/egirl_money
*/

pragma solidity ^0.8.19;






contract SimpFarm is Ownable {
    // emit payment events
    event IERC20TransferEvent(IERC20 indexed token, address to, uint256 amount);
    event IERC20TransferFromEvent(
        IERC20 indexed token,
        address from,
        address to,
        uint256 amount
    );

    //variables
    Simp simp;
    address public simpAddress;
    IERC20 public usdc;
    address public usdcAddress;

    address public pair;
    address public treasury;
    address public dev;

    uint256 public dailyInterest;
    uint256 public nodeCost;
    uint256 public nodeBase;
    uint256 public bondDiscount;

    uint256 public claimTaxSimp = 8;
    uint256 public claimTaxBond = 12;
    uint256 public treasuryShare = 2;
    uint256 public devShare = 1;
    uint256 public presalePrice = 1;
    uint256 public referShare = 1;

    bool public isLive;
    bool public presaleLive;

    uint256 totalNodes = 0;
    mapping(address => address) public referers;

    //Array
    address[] public farmersAddresses;

    //Farmers Struct
    struct Farmer {
        bool exists;
        uint256 SimpNodes;
        uint256 bondNodes;
        uint256 claimsSimp;
        uint256 claimsBond;
        uint256 lastUpdate;
    }

    //mappings
    mapping(address => Farmer) public farmers;

    uint256 public totalReceivedEth;

    event ReferBuy(
        address buyer,
        address referer,
        uint256 amount,
        address token
    );
    event NodeBuy(address buyer, uint256 nodes, uint256 amount, address token);

    //constructor
    constructor(
        address _simp, //address of a standard erc20 to use in the platform
        address _usdc, //address of an erc20 stablecoin
        address _pair, //address of potential liquidity pool
        address _treasury, //address of a trasury wallet to hold fees and taxes
        address _dev, //address of developer
        uint256 _dailyInterest,
        uint256 _nodeCost,
        uint256 _nodeBase,
        uint256 _bondDiscount
    ) {
        _initializeOwner(msg.sender);
        simp = Simp(_simp);
        usdc = IERC20(_usdc);
        pair = _pair;
        treasury = _treasury;
        dev = _dev;
        dailyInterest = _dailyInterest;
        nodeCost = _nodeCost * 1e18;
        nodeBase = _nodeBase * 1e18;
        bondDiscount = _bondDiscount;
        simpAddress = _simp;
        usdcAddress = _usdc;
    }

    //Price Checking Functions
    function getSimpBalance() external view returns (uint256) {
        return simp.balanceOf(pair);
    }

    function getUSDCBalance() external view returns (uint256) {
        return usdc.balanceOf(pair);
    }

    function getPrice() public view returns (uint256) {
        uint256 SimpBalance = simp.balanceOf(pair);
        uint256 usdcBalance = usdc.balanceOf(pair);
        require(SimpBalance > 0, "divison by zero error");
        uint256 price = (usdcBalance * 1e30) / SimpBalance;
        return price;
    }

    //Bond Setup
    function getBondCost() public view returns (uint256) {
        uint256 tokenPrice = getPrice();
        uint256 basePrice = ((nodeCost / 1e18) * tokenPrice) / 1e12;
        uint256 discount = 100 - bondDiscount;
        uint256 bondPrice = (basePrice * discount) / 100;
        return bondPrice;
    }

    function setBondDiscount(uint256 newDiscount) public onlyOwner {
        require(newDiscount <= 25, "Discount above limit");
        bondDiscount = newDiscount;
    }

    //Set Refer %
    function setReferPercentage(uint256 _referShare) public onlyOwner {
        referShare = _referShare;
    }

    //Set Addresses
    function setTokenAddr(address tokenAddress) public onlyOwner {
        simp = Simp(tokenAddress);
    }

    function setUSDCAddr(address tokenAddress) public onlyOwner {
        usdc = IERC20(tokenAddress);
    }

    function setPairAddr(address pairAddress) public onlyOwner {
        pair = pairAddress;
    }

    function setTreasuryAddr(address treasuryAddress) public onlyOwner {        
        treasury = treasuryAddress;
    }

    //Platform Settings
    function setPresaleState(bool _isLive) public onlyOwner {
        presaleLive = _isLive;
    }

    //Platform Settings
    function setPlatformState(bool _isLive) public onlyOwner {
        isLive = _isLive;
    }

    function setTreasuryShare(uint256 _treasuryShare) public onlyOwner {
        treasuryShare = _treasuryShare;
    }

    function setDevShare(uint256 _devShare) public onlyOwner {
        devShare = _devShare;
    }

    function setSimpTax(uint256 _claimTaxSimp) public onlyOwner {
        claimTaxSimp = _claimTaxSimp;
    }

    function setBondTax(uint256 _claimTaxBond) public onlyOwner {
        claimTaxBond = _claimTaxBond;
    }

    function setDailyInterest(uint256 newInterest) public onlyOwner {
        updateAllClaims();
        dailyInterest = newInterest;
    }

    function setPresalePrice(uint256 _presalePrice) public onlyOwner {
        presalePrice = _presalePrice;
    }

    function updateAllClaims() internal {
        uint256 i;
        for (i = 0; i < farmersAddresses.length; i++) {
            address _address = farmersAddresses[i];
            updateClaims(_address);
        }
    }

    function setNodeCost(uint256 newNodeCost) public onlyOwner {
        nodeCost = newNodeCost;
    }

    function setNodeBase(uint256 newBase) public onlyOwner {
        nodeBase = newBase;
    }

    //Node management - Buy - Claim - Bond - User front
    function buyNode(uint256 _amount, address referer) external payable {
        require(isLive, "Platform is offline");
        Farmer memory farmer;
        if (farmers[msg.sender].exists) {
            farmer = farmers[msg.sender];
        } else {
            farmer = Farmer(true, 0, 0, 0, 0, 0);
            farmersAddresses.push(msg.sender);
        }
        address ref = referer != address(0) ? referer : referers[msg.sender];
        uint256 transactionTotal = nodeCost * _amount;
        if (ref != address(0)) {
            uint256 toRef = (transactionTotal / 10) * referShare;
            simp.transferFrom(msg.sender, ref, toRef);
            emit ReferBuy(msg.sender, ref, toRef, simpAddress);
            transactionTotal = transactionTotal - toRef;
            if (referer != address(0) && referers[msg.sender] == address(0)) {
                referers[msg.sender] = referer;
            }
        }
        uint256 toDev = (transactionTotal / 10) * devShare;
        uint256 toTreasury = (transactionTotal / 10) * treasuryShare;
        uint256 toPool = transactionTotal - toDev - toTreasury;
        simp.farmBurn(msg.sender, toPool);
        simp.farmBurn(msg.sender, toTreasury);
        simp.farmBurn(msg.sender, toDev);
        farmers[msg.sender] = farmer;
        updateClaims(msg.sender);
        farmers[msg.sender].SimpNodes += _amount;
        emit NodeBuy(
            msg.sender,
            _amount,
            (toPool + toTreasury + toDev),
            simpAddress
        );
        totalNodes += _amount;
    }

    function bondNode(uint256 _amount, address referer) external payable {
        require(isLive || presaleLive, "Platform is offline");
        Farmer memory farmer;
        if (farmers[msg.sender].exists) {
            farmer = farmers[msg.sender];
        } else {
            farmer = Farmer(true, 0, 0, 0, 0, 0);
            farmersAddresses.push(msg.sender);
        }
        uint256 usdcAmount;
        uint256 transactionTotal;
        if (presaleLive) {
            usdcAmount = presalePrice;
        } else {
            usdcAmount = getBondCost();
        }
        transactionTotal = usdcAmount * _amount;

        address ref = referer != address(0) ? referer : referers[msg.sender];
        if (ref != address(0)) {
            uint256 toRef = (transactionTotal / 10) * referShare;
            _transferFrom(usdc, ref, address(this), toRef);
            emit ReferBuy(msg.sender, ref, toRef, usdcAddress);
            transactionTotal = transactionTotal - toRef;
            if (referer != address(0) && referers[msg.sender] == address(0)) {
                referers[msg.sender] = referer;
            }
        }

        uint256 toDev = (transactionTotal / 10) * devShare;
        uint256 toTreasury = transactionTotal - toDev;
        _transferFrom(usdc, msg.sender, address(dev), toDev);
        _transferFrom(usdc, msg.sender, address(treasury), toTreasury);
        farmers[msg.sender] = farmer;
        updateClaims(msg.sender);
        farmers[msg.sender].bondNodes += _amount;
        emit NodeBuy(msg.sender, _amount, (toTreasury + toDev), usdcAddress);
        totalNodes += _amount;
    }

    function awardNode(address _address, uint256 _amount) public onlyOwner {
        uint256 nodesOwned = farmers[_address].SimpNodes +
            farmers[_address].bondNodes +
            _amount;
        require(nodesOwned < 101, "Max baskets Owned");
        Farmer memory farmer;
        if (farmers[_address].exists) {
            farmer = farmers[_address];
        } else {
            farmer = Farmer(true, 0, 0, 0, 0, 0);
            farmersAddresses.push(_address);
        }
        farmers[_address] = farmer;
        updateClaims(_address);
        farmers[_address].SimpNodes += _amount;
        totalNodes += _amount;
        farmers[_address].lastUpdate = block.timestamp;
    }

    function compoundNode() public returns (uint256){
        updateClaims(msg.sender);

        uint256 simpNodesToCreate = farmers[msg.sender].claimsSimp > nodeCost ? farmers[msg.sender].claimsSimp / nodeCost : 0;
        uint256 bondNodesToCreate = farmers[msg.sender].claimsBond > nodeCost ? farmers[msg.sender].claimsBond / nodeCost : 0;

        require(
            simpNodesToCreate > 0 || bondNodesToCreate > 0,
            "Not enough claims to compound"
        );

        if (simpNodesToCreate > 0) {
            uint256 totalSimpCost = simpNodesToCreate * nodeCost;
            farmers[msg.sender].claimsSimp -= totalSimpCost;
            farmers[msg.sender].SimpNodes += simpNodesToCreate;
        }

        if (bondNodesToCreate > 0) {
            uint256 totalBondCost = bondNodesToCreate * nodeCost;
            farmers[msg.sender].claimsBond -= totalBondCost;
            farmers[msg.sender].bondNodes += bondNodesToCreate;
        }

        totalNodes += (simpNodesToCreate + bondNodesToCreate);
        return (simpNodesToCreate + bondNodesToCreate);
    }    

    function updateClaims(address _address) internal {
        uint256 time = block.timestamp;
        uint256 timerFrom = farmers[_address].lastUpdate;
        if (timerFrom > 0)
            farmers[_address].claimsSimp +=
                (farmers[_address].SimpNodes *
                    nodeBase *
                    dailyInterest *
                    (time - timerFrom)) /
                8640000;
        farmers[_address].claimsBond +=
            (farmers[_address].bondNodes *
                nodeBase *
                dailyInterest *
                (time - timerFrom)) /
            8640000;
        farmers[_address].lastUpdate = time;
    }

    function getTotalClaimable() public view returns (uint256) {
        uint256 time = block.timestamp;
        uint256 pendingSimp = (farmers[msg.sender].SimpNodes *
            nodeBase *
            dailyInterest *
            (time - farmers[msg.sender].lastUpdate)) / 8640000;
        uint256 pendingBond = (farmers[msg.sender].bondNodes *
            nodeBase *
            dailyInterest *
            (time - farmers[msg.sender].lastUpdate)) / 8640000;
        uint256 pending = pendingSimp + pendingBond;
        return
            farmers[msg.sender].claimsSimp +
            farmers[msg.sender].claimsBond +
            pending;
    }

    function getTaxEstimate() external view returns (uint256) {
        uint256 time = block.timestamp;
        uint256 pendingSimp = (farmers[msg.sender].SimpNodes *
            nodeBase *
            dailyInterest *
            (time - farmers[msg.sender].lastUpdate)) / 8640000;
        uint256 pendingBond = (farmers[msg.sender].bondNodes *
            nodeBase *
            dailyInterest *
            (time - farmers[msg.sender].lastUpdate)) / 8640000;
        uint256 claimableSimp = pendingSimp + farmers[msg.sender].claimsSimp;
        uint256 claimableBond = pendingBond + farmers[msg.sender].claimsBond;
        uint256 taxSimp = (claimableSimp / 100) * claimTaxSimp;
        uint256 taxBond = (claimableBond / 100) * claimTaxBond;
        return taxSimp + taxBond;
    }

    function calculateTax() public returns (uint256) {
        updateClaims(msg.sender);
        uint256 taxSimp = (farmers[msg.sender].claimsSimp / 100) * claimTaxSimp;
        uint256 taxBond = (farmers[msg.sender].claimsBond / 100) * claimTaxBond;
        uint256 tax = taxSimp + taxBond;
        return tax;
    }

    function claim() external payable {
        // ensure msg.sender is sender
        require(
            farmers[msg.sender].exists,
            "sender must be registered farmer to claim yields"
        );

        updateClaims(msg.sender);
        uint256 tax = calculateTax();
        uint256 reward = farmers[msg.sender].claimsSimp +
            farmers[msg.sender].claimsBond;
        uint256 toTreasury = tax;
        uint256 toFarmer = reward - tax;
        if (reward > 0) {
            farmers[msg.sender].claimsSimp = 0;
            farmers[msg.sender].claimsBond = 0;
            simp.farmMint(msg.sender, toFarmer);
            simp.farmMint(address(treasury), toTreasury);
        }
    }

    //Platform Info
    function currentDailyRewards() external view returns (uint256) {
        uint256 dailyRewards = (nodeBase * dailyInterest) / 100;
        return dailyRewards;
    }

    function getOwnedNodes() external view returns (uint256) {
        uint256 ownedNodes = farmers[msg.sender].SimpNodes +
            farmers[msg.sender].bondNodes;
        return ownedNodes;
    }

    function getTotalNodes() external view returns (uint256) {
        return totalNodes;
    }

    function getSimpClaimTax() external view returns (uint256) {
        return claimTaxSimp;
    }

    function getBondClaimTax() external view returns (uint256) {
        return claimTaxBond;
    }

    // SafeERC20 transfer
    function _transfer(
        IERC20 token,
        address account,
        uint256 amount
    ) private {
        SafeERC20.safeTransfer(token, account, amount);
        // log transfer to blockchain
        emit IERC20TransferEvent(token, account, amount);
    }

    // SafeERC20 transferFrom
    function _transferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) private {
        SafeERC20.safeTransferFrom(token, from, to, amount);
        // log transferFrom to blockchain
        emit IERC20TransferFromEvent(token, from, to, amount);
    }

    receive() external payable {}
}