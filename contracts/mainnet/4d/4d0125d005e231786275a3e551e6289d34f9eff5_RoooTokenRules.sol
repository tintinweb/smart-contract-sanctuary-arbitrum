/**
 *Submitted for verification at Arbiscan on 2023-06-05
*/

//          ___           ___           ___           ___     
//         /\  \         /\  \         /\  \         /\  \    
//        /::\  \       /::\  \       /::\  \       /::\  \   
//       /:/\:\  \     /:/\:\  \     /:/\:\  \     /:/\:\  \  
//      /::\~\:\  \   /:/  \:\  \   /:/  \:\  \   /:/  \:\  \ 
//     /:/\:\ \:\__\ /:/__/ \:\__\ /:/__/ \:\__\ /:/__/ \:\__\
//     \/_|::\/:/  / \:\  \ /:/  / \:\  \ /:/  / \:\  \ /:/  /
//        |:|::/  /   \:\  /:/  /   \:\  /:/  /   \:\  /:/  / 
//        |:|\/__/     \:\/:/  /     \:\/:/  /     \:\/:/  /  
//        |:|  |        \::/  /       \::/  /       \::/  /   
//         \|__|         \/__/         \/__/         \/__/    
//
//                         www.rooo.space


// Dependency file: contracts/interfaces/IRoooTokenRules.sol

// SPDX-License-Identifier: MIT
// pragma solidity ^0.8.2;

interface IRoooTokenRules {
    struct Fees {
        uint16 liquidity;
        uint16 burn;
        uint16 holders;
        uint16 marketing;
        uint16 dev;
    }

    struct Rules {
        uint8 id;
        uint24 from;
        uint24 to;
        uint256 min;
        Fees buy;
        Fees sell;
    }

    function getLastLevel() external view returns (uint8);

    function getRulesByLevel(
        uint8 level
    ) external view returns (Rules calldata);

    function getRules(uint24 holders) external view returns (Rules calldata);
}


// Root file: contracts/RoooTokenRules.sol

pragma solidity 0.8.19;

// import "contracts/interfaces/IRoooTokenRules.sol";

contract RoooTokenRules is IRoooTokenRules {
    Rules[] private _rules;

    constructor() {
        _rules.push(
            Rules({
                id: 0,
                from: 0,
                to: 93,
                min: 1_000_000_000_000 ether,
                buy: Fees({
                    burn: 200,
                    holders: 100,
                    dev: 100,
                    marketing: 100,
                    liquidity: 200
                }),
                sell: Fees({
                    burn: 625,
                    holders: 575,
                    dev: 575,
                    marketing: 575,
                    liquidity: 625
                })
            })
        );

        _rules.push(
            Rules({
                id: 1,
                from: 93,
                to: 150,
                min: 100_000_000_000 ether,
                buy: Fees({
                    burn: 200,
                    holders: 100,
                    dev: 100,
                    marketing: 100,
                    liquidity: 200
                }),
                sell: Fees({
                    burn: 600,
                    holders: 550,
                    dev: 550,
                    marketing: 550,
                    liquidity: 600
                })
            })
        );

        _rules.push(
            Rules({
                id: 2,
                from: 150,
                to: 828,
                min: 10_000_000_000 ether,
                buy: Fees({
                    burn: 200,
                    holders: 100,
                    dev: 100,
                    marketing: 100,
                    liquidity: 200
                }),
                sell: Fees({
                    burn: 550,
                    holders: 500,
                    dev: 500,
                    marketing: 500,
                    liquidity: 550
                })
            })
        );

        _rules.push(
            Rules({
                id: 3,
                from: 828,
                to: 3_000,
                min: 3_000_000_000 ether,
                buy: Fees({
                    burn: 200,
                    holders: 100,
                    dev: 100,
                    marketing: 100,
                    liquidity: 200
                }),
                sell: Fees({
                    burn: 500,
                    holders: 450,
                    dev: 450,
                    marketing: 450,
                    liquidity: 500
                })
            })
        );

        _rules.push(
            Rules({
                id: 4,
                from: 3_000,
                to: 10_000,
                min: 1_000_000_000 ether,
                buy: Fees({
                    burn: 200,
                    holders: 100,
                    dev: 100,
                    marketing: 100,
                    liquidity: 200
                }),
                sell: Fees({
                    burn: 450,
                    holders: 400,
                    dev: 400,
                    marketing: 400,
                    liquidity: 450
                })
            })
        );

        _rules.push(
            Rules({
                id: 5,
                from: 10_000,
                to: 50_000,
                min: 100_000_000 ether,
                buy: Fees({
                    burn: 200,
                    holders: 100,
                    dev: 100,
                    marketing: 100,
                    liquidity: 200
                }),
                sell: Fees({
                    burn: 425,
                    holders: 300,
                    dev: 300,
                    marketing: 300,
                    liquidity: 425
                })
            })
        );

        _rules.push(
            Rules({
                id: 6,
                from: 50_000,
                to: 100_000,
                min: 50_000_000 ether,
                buy: Fees({
                    burn: 200,
                    holders: 100,
                    dev: 100,
                    marketing: 100,
                    liquidity: 200
                }),
                sell: Fees({
                    burn: 400,
                    holders: 200,
                    dev: 200,
                    marketing: 200,
                    liquidity: 400
                })
            })
        );

        _rules.push(
            Rules({
                id: 7,
                from: 100_000,
                to: 300_000,
                min: 20_000_000 ether,
                buy: Fees({
                    burn: 200,
                    holders: 100,
                    dev: 100,
                    marketing: 100,
                    liquidity: 200
                }),
                sell: Fees({
                    burn: 300,
                    holders: 150,
                    dev: 150,
                    marketing: 150,
                    liquidity: 300
                })
            })
        );

        _rules.push(
            Rules({
                id: 8,
                from: 300_000,
                to: 384_000,
                min: 10_000_000 ether,
                buy: Fees({
                    burn: 100,
                    holders: 50,
                    dev: 50,
                    marketing: 50,
                    liquidity: 100
                }),
                sell: Fees({
                    burn: 200,
                    holders: 100,
                    dev: 100,
                    marketing: 100,
                    liquidity: 200
                })
            })
        );

        _rules.push(
            Rules({
                id: 9,
                from: 384_000,
                to: type(uint24).max,
                min: 0,
                buy: Fees({
                    burn: 0,
                    holders: 0,
                    dev: 0,
                    marketing: 0,
                    liquidity: 0
                }),
                sell: Fees({
                    burn: 0,
                    holders: 0,
                    dev: 0,
                    marketing: 0,
                    liquidity: 0
                })
            })
        );
    }

    function getLastLevel() external view override returns (uint8) {
        return uint8(_rules.length - 1);
    }

    function getRulesByLevel(
        uint8 level
    ) external view override returns (Rules memory) {
        return _rules[uint256(level)];
    }

    function getRules(
        uint24 holders
    ) external view override returns (Rules memory) {
        for (uint256 i = 0; i < _rules.length; i++) {
            if (_rules[i].from <= holders && _rules[i].to > holders) {
                return _rules[i];
            }
        }
        return _rules[_rules.length - 1];
    }
}