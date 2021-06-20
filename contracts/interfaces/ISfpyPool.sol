// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISfpyPool {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address owner) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 value) external returns (bool);
    function transfer(address to, uint256 value) external returns (bool);
    function nonces(address owner) external view returns (uint256);
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed owner, uint256 amount);
    event Burn(address indexed owner, uint256 amount, address indexed to);
    event Sync(uint112 reserve);

    function factory() external view returns (address);
    function token() external view returns (address);
    function getReserves() external view returns (uint112 reserve, uint32 blockTimestampLast);
    function liquidityToBurn(uint256 amount) external view returns (uint256 liquidity);
    function mint(address to) external returns (uint256 liquidity);
    function burn(address to) external returns (uint256 amount);
    function borrow(uint256 amountOut, address to, bytes calldata data) external;
    function initialize(address) external;
}
