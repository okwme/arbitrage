pragma solidity ^0.5.0;
import "./Arbitrage.sol";
/// @title Uniswap Arbitrage Module - Executes arbitrage transactions between Uniswap and DutchX.
/// @author Billy Rennekamp - <billy@gnosis.pm>
contract ArbitrageRinkeby is Arbitrage {
    constructor() public {
        uniFactory = IUniswapFactory(0xf5D915570BC477f9B8D6C0E980aA81757A3AaC36); 
        dutchXProxy = IDutchExchange(0x4e69969D9270fF55fc7c5043B074d4e45F795587);
    }
}