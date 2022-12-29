// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library WorldConstants {

    //special actors ID
    uint256 public constant ACTOR_PANGU = 1;

    //actor attributes ID
    uint256 public constant ATTR_BASE = 0;
    uint256 public constant ATTR_AGE = 0; // 年龄
    uint256 public constant ATTR_HLH = 1; // 健康，生命

    //module ID
    uint256 public constant WORLD_MODULE_ACTORS       = 0;  //角色
    uint256 public constant WORLD_MODULE_RANDOM       = 1;  //随机数
    uint256 public constant WORLD_MODULE_NAMES        = 2;  //姓名
    uint256 public constant WORLD_MODULE_COIN         = 3;  //通货
    uint256 public constant WORLD_MODULE_YEMINGS      = 4;  //噎明权限
    uint256 public constant WORLD_MODULE_ZONES        = 5;  //区域
    uint256 public constant WORLD_MODULE_SIDS         = 6;  //身份
    uint256 public constant WORLD_MODULE_ITEMS        = 7;  //物品
    uint256 public constant WORLD_MODULE_PRELIFES     = 8;  //前世
    uint256 public constant WORLD_MODULE_ACTOR_LOCATIONS    = 9;  //角色定位

    uint256 public constant WORLD_MODULE_TRIGRAMS_RENDER    = 10; //角色符文渲染器
    uint256 public constant WORLD_MODULE_TRIGRAMS           = 11; //角色符文数据

    uint256 public constant WORLD_MODULE_SIFUS        = 12; //师傅令牌
    uint256 public constant WORLD_MODULE_ATTRIBUTES   = 13; //角色基本属性
}