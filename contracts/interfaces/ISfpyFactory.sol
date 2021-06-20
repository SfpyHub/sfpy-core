// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISfpyFactory {
    event PoolCreated(address indexed token, address pool);

    function createPool(address token) external returns (address created);

    function pool(address token) external view returns (address);
    function pools() external view returns (uint256);

    function owner() external view returns (address);
    function setOwner(address) external;
}
