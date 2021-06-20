// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './libraries/Math.sol';
import './interfaces/ISfpyPool.sol';
import './interfaces/ISfpyERC20.sol';
import './interfaces/ISfpyFactory.sol';
import './interfaces/ISfpyBorrower.sol';

import './SfpyERC20.sol';

contract SfpyPool is SfpyERC20 {
    using SafeMath for uint256;

    uint256 private constant ETHER = 1 ether;
    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));
    address private _factory;
    address private _token;
    uint112 private reserve;
    uint32 private blockTimestampLast;

    uint256 private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, 'SFPY: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    /// @dev Get the pool's balance of token
    function getReserves() public view returns (uint112 _reserve, uint32 _blockTimestampLast) {
        _reserve = reserve;
        _blockTimestampLast = blockTimestampLast;
    }

    function _safeTransfer(
        address to,
        uint256 value
    ) private {
        (bool success, bytes memory data) = _token.call(abi.encodeWithSelector(SELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SFPY: TRANSFER_FAILED');
    }

    event Mint(address indexed sender, uint256 amount);
    event Burn(address indexed sender, uint256 amount, address indexed to);
    event Sync(uint112 reserve);

    constructor() {
        _factory = msg.sender;
    }

    function initialize(address t) external {
        require(msg.sender == _factory, 'SFPY: FORBIDDEN');
        _token = t;
    }

    /// @dev updates the reserve value of the pool after every
    /// @dev interaction that changes state such as mint, burn 
    /// @dev and borrow
    /// @param balance the updated reserve value of the pool
    function _update(uint256 balance) private {
        require(balance <= 2**112 - 1, 'SFPY: OVERFLOW');
        uint32 blockTimestamp = uint32(block.timestamp % 2**32);
        reserve = uint112(balance);
        blockTimestampLast = blockTimestamp;
        emit Sync(reserve);
    }

    /// @dev calculates the amount of liquidity tokens needed to be burnt
    /// @dev given an amount of the underlying token
    /// @param amount the amount of ERC-20 tokens that is needed
    function liquidityToBurn(uint256 amount) public view returns (uint256 liquidity) {
        uint256 _ts = totalSupply();
        uint256 balance = ISfpyERC20(_token).balanceOf(address(this));
        require(balance > 0, 'SFPY: INSUFFICIENT_BALANCE');
        liquidity = amount.mul(_ts) / balance;
        require(liquidity > 0, 'SFPY: INSUFFICIENT_LIQUIDITY');
    }

    /// @dev mints liquidity tokens pro rata based on the amount of the 
    /// @dev underlying ERC-20 token that was transferred to the pool
    /// @param to the address to mint the liquidity tokens to
    function mint(address to) external lock returns (uint256 liquidity) {
        (uint112 _reserve, ) = getReserves(); // gas savings
        uint256 balance = ISfpyERC20(_token).balanceOf(address(this));
        uint256 amount = balance.sub(_reserve);
        uint256 _ts = totalSupply();
        if (_ts == 0) {
            liquidity = Math.sqrt(amount.mul(ETHER));
        } else {
            liquidity = amount.mul(ETHER) / _ts;
        }
        require(liquidity > 0, 'SFPY: INSUFFICIENT_LIQUIDITY_MINTED');
        _mint(to, liquidity);
        _update(balance);
        emit Mint(msg.sender, amount);
    }

    /// @dev converts pool liquidity tokens into underlying ERC-20 tokens
    /// @dev and sends them to the address specified
    /// @param to the address to send the underlying tokens to
    function burn(address to) external lock returns (uint256 amount) {
        uint256 balance = ISfpyERC20(_token).balanceOf(address(this));
        uint256 liquidity = balanceOf(address(this));
        uint256 _ts = totalSupply();
        amount = liquidity.mul(balance) / _ts;
        require(amount > 0, 'SFPY: INSUFFICIENT_LIQUIDITY_BURNED');
        _burn(address(this), liquidity);
        _safeTransfer(to, amount);
        balance = ISfpyERC20(_token).balanceOf(address(this));
        _update(balance);
        emit Burn(msg.sender, amount, to);
    }

    /// @dev Borrows funds from the pool 
    /// @param amountOut the amount requested
    /// @param to the address to send the funds to
    /// @param data any data that might be needed during call execution
    function borrow(uint amountOut, address to, bytes calldata data) external lock {
        require(amountOut > 0, 'SFPY: INSUFFICIENT_OUTPUT_AMOUNT');
        (uint112 _reserve, ) = getReserves(); // gas savings
        require(amountOut < _reserve, 'SFPY: INSUFFICIENT_LIQUIDITY');

        require(to != _token, 'SFPY: INVALID_TO');
        if (amountOut > 0) _safeTransfer(to, amountOut); // optimistically transfer tokens
        ISfpyBorrower(to).borrow(msg.sender, amountOut, data);
        uint256 balance = ISfpyERC20(_token).balanceOf(address(this));
        uint256 amountIn = balance > _reserve - amountOut ? balance - (_reserve - amountOut) : 0;
        require(amountIn > 0, 'SFPY: ZERO_INPUT_AMOUNT');
        uint256 feeAmount = amountOut.mul(10 ** 15) / (10 ** 18); // .1% fee (10 ** 15 / 10*18)
        require(amountIn >= amountOut.add(feeAmount), 'SFPY: INSUFFICIENT_INPUT_AMOUNT');
        require(balance >= _reserve, 'SFPY: INSUFFICIENT BALANCE');
        _update(balance);
    }

    /// @dev returns the address of the factory
    function factory() external view returns (address) {
        return _factory;
    }

    /// @dev returns the underlying ERC-20 token of this pool
    function token() external view returns (address) {
        return _token;
    }
}
