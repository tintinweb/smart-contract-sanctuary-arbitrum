// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library DahuangConstants {

    //actor attributes ID
    uint256 public constant ATTR_BASE = 10; // ID起始值
    uint256 public constant ATTR_BASE_CHARM = ATTR_BASE; // ID起始值
    uint256 public constant ATTR_MEL = ATTR_BASE_CHARM + 0; // 魅力
    uint256 public constant ATTR_BASE_MOOD = 20; // ID起始值
    uint256 public constant ATTR_XIQ = ATTR_BASE_MOOD + 0; // 心情
    uint256 public constant ATTR_BASE_CORE = 30; // ID起始值
    uint256 public constant ATTR_LVL = ATTR_BASE_CORE + 0; // 膂力
    uint256 public constant ATTR_TIZ = ATTR_BASE_CORE + 1; // 体质
    uint256 public constant ATTR_LIM = ATTR_BASE_CORE + 2; // 灵敏
    uint256 public constant ATTR_GEG = ATTR_BASE_CORE + 3; // 根骨
    uint256 public constant ATTR_WUX = ATTR_BASE_CORE + 4; // 悟性
    uint256 public constant ATTR_DIL = ATTR_BASE_CORE + 5; // 定力
    uint256 public constant ATTR_BASE_BEHAVIOR = 40;
    uint256 public constant ATTR_ACT = ATTR_BASE_BEHAVIOR + 0; // 行动力

    //module ID
    uint256 public constant WORLD_MODULE_TIMELINE     = 200;
    uint256 public constant WORLD_MODULE_EVENTS       = 201;
    uint256 public constant WORLD_MODULE_TALENTS      = 202;

    uint256 public constant WORLD_MODULE_CHARM_ATTRIBUTES       = 203; //魅力属性
    uint256 public constant WORLD_MODULE_MOOD_ATTRIBUTES        = 204; //情绪属性
    uint256 public constant WORLD_MODULE_CORE_ATTRIBUTES        = 205; //核心属性
    uint256 public constant WORLD_MODULE_BEHAVIOR_ATTRIBUTES    = 206; //行动属性

    uint256 public constant WORLD_MODULE_FOOD         = 207; //食材
    uint256 public constant WORLD_MODULE_WOOD         = 208; //木材
    uint256 public constant WORLD_MODULE_GOLD         = 209; //金石
    uint256 public constant WORLD_MODULE_FABRIC       = 210; //织物
    uint256 public constant WORLD_MODULE_HERB         = 211; //药材
    uint256 public constant WORLD_MODULE_PRESTIGE     = 212; //威望

    uint256 public constant WORLD_MODULE_RELATIONSHIP = 213; //关系
    uint256 public constant WORLD_MODULE_SEASONS      = 214; //出生时节
    uint256 public constant WORLD_MODULE_BORN_PLACES  = 215; //出生地
    uint256 public constant WORLD_MODULE_ZONE_BASE_RESOURCES    = 216; //地区基本资源
    uint256 public constant WORLD_MODULE_VILLAGES     = 217; //聚居区（村庄）
    uint256 public constant WORLD_MODULE_BUILDINGS    = 218; //建筑物
}