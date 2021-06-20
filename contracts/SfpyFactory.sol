// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './interfaces/ISfpyFactory.sol';
import './SfpyPool.sol';

contract SfpyFactory is ISfpyFactory {
    address private _owner;

    mapping(address => address) private _pools;
    address[] private _allPools;

    /// @dev sets the owner of the factory
    /// @dev responsible for creating pools
    constructor(address o) {
        _owner = o;
    }

    /// @dev given an address of an ERC-20 token, creates a pool
    /// @dev and initializes it. This is gas optimized to use the
    /// @dev CREATE2 op code when creating a pool.
    /// @param token the ERC-20 token to create the pool for
    function createPool(address token) external override returns (address created) {
        require(msg.sender == _owner, 'SFPY: FORBIDDEN');
        require(token != address(0), 'SFPY: ZERO_ADDRESS');
        require(_pools[token] == address(0), 'SFPY: POOL_EXISTS');
        bytes memory bytecode = type(SfpyPool).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token));
        assembly {
            created := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        ISfpyPool(created).initialize(token);
        _pools[token] = created;
        _allPools.push(created);
        emit PoolCreated(token, created);
    }

    /// @dev returns the total number of pools created
    function pools() external view override returns (uint256) {
        return _allPools.length;
    }

    /// @dev given an address, returns the address of the underlying pool
    /// @param token the address of the underlying ERC-20 token
    function pool(address token) external view override returns (address) {
        return _pools[token];
    }

    /// @dev sets the owner of the factory
    /// @param o the new owner
    function setOwner(address o) external override {
        require(msg.sender == _owner, 'SFPY: FORBIDDEN');
        _owner = o;
    }

    /// @dev returns the current owner of the factory
    function owner() external view override returns (address) {
        return _owner;
    }
}
