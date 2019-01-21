pragma solidity ^0.5.0;

import "./UniswapExchangeInterface.sol";
import "./UniswapFactoryInterface.sol";
import "./DutchExchangeInterface.sol";

/**
 * The Arbitrage contract
 */
contract Arbitrage {

    enum Network {Mainnet, Rinkeby}

    UniswapFactoryInterface uniFactory;
    DutchExchangeInterface dutchXProxy;
    
    constructor(Network _network) public {
        if (_network == Network.Mainnet) {
            uniFactory = UniswapFactoryInterface(0xc0a47dFe034B400B47bDaD5FecDa2621de6c4d95);
            dutchXProxy = DutchExchangeInterface(0xaf1745c0f8117384Dfa5FFf40f824057c70F2ed3);
        } else {
            uniFactory = UniswapFactoryInterface(0xf5D915570BC477f9B8D6C0E980aA81757A3AaC36);
            dutchXProxy = DutchExchangeInterface(0x4e69969D9270fF55fc7c5043B074d4e45F795587);
        }
    }

    function dutchOpportunity(address token1, uint256 amount) public {
        uint256 startGas = gasleft();
        address token2 = dutchXProxy.ethToken();
        address uniswapExchangeToken = uniFactory.getExchange(token1);
        uint256 dutchAuctionIndex = dutchXProxy.getAuctionIndex(token1, token2);

        uint256 tokensBought = dutchXProxy.postBuyOrder(token2, token1, dutchAuctionIndex, amount);
        uint256 etherReturned = UniswapExchangeInterface(uniswapExchangeToken).tokenToEthSwapInput(tokensBought, amount, block.timestamp);
        uint256 gasUsed = (startGas - gasleft()) * tx.gasprice;
        require((etherReturned - gasUsed) >= amount, "no profit");
    }

    function uniswapOpportunity(address token1, uint256 amount) public payable {
        require(msg.value == amount, "buying from uniswap takes real Ether");

        uint256 startGas = gasleft();
        address token2 = dutchXProxy.ethToken();
        address uniswapExchangeToken = uniFactory.getExchange(token1);
        uint256 dutchAuctionIndex = dutchXProxy.getAuctionIndex(token1, token2);

        uint256 tokensBought = UniswapExchangeInterface(uniswapExchangeToken).ethToTokenSwapInput.value(amount)(0, block.timestamp);
        uint256 etherReturned;
        (dutchAuctionIndex, etherReturned) = dutchXProxy.postSellOrder(token1, token2, dutchAuctionIndex, tokensBought);
        uint256 gasUsed = (startGas - gasleft()) * tx.gasprice;
        require((etherReturned - gasUsed) >= amount, "no profit");
    }

    // this will assume that all dutchX tokens relative to the arbitrage will have already been deposited
    // this will assume that all tokens have been given the proper transfer allowances
    // this will also assume that any Ether to be spent on uniswap will be included with the tx as msg.value
    // in order to save gas costs on transferring Ether token to and from Eth
    function preCheck(address token, uint256 amount) public payable returns (uint256) {
        require(token != address(0), "why no token?");

        address uniswapExchangeToken = uniFactory.getExchange(token);
        uint256 uniswapTokensReturned = UniswapExchangeInterface(uniswapExchangeToken).getEthToTokenInputPrice(amount);

        address dutchEther = dutchXProxy.ethToken();
        uint256 dutchAuctionIndex = dutchXProxy.getAuctionIndex(token, dutchEther);

        (uint256 dutchTokenResult, uint256 dutchEtherResult) = dutchXProxy.getCurrentAuctionPrice(dutchEther, token, dutchAuctionIndex);

        // buy dutch sell uni

        // uniswapPrice = uniswapTokensReturned / amount; // dai per ether
        // dutchPrice = dutchTokenResult / dutchEtherResult; // dai per ether
        // if (dutchPrice < uniswapPrice) {
        // if ((num1 * den2) < (num2 * den1)) {
        if ((dutchTokenResult * amount) < (uniswapTokensReturned * dutchEtherResult)) {
            
            // calculating the result of buy including fees is maybe unnecessary
            // if we have a lot of mag they will be very minimal?

            // uint sellVolume = dutchXProxy.sellVolumesCurrent[dutchEther][token];
            // uint buyVolume = buyVolumes[dutchEther][token];
            // uint outstandingVolume = dutchXProxy.atleastZero(int(mul(sellVolume, dutchTokenResult) / dutchEtherResult - buyVolume));
            
            // uint amountAfterFee;
            // if (amount < outstandingVolume) {
            //     if (amount > 0) {
            //         amountAfterFee = dutchXProxy.settleFee(token, dutchEther, dutchAuctionIndex, amount);
            //     }
            // } else {
            //     amount = outstandingVolume;
            //     amountAfterFee = outstandingVolume;
            // }
            // //

            uint256 tokensBought = dutchXProxy.postBuyOrder(dutchEther, token, dutchAuctionIndex, amount);
            uint256 etherReturned = UniswapExchangeInterface(uniswapExchangeToken).tokenToEthSwapInput(tokensBought, amount, block.timestamp);
            
            require(etherReturned > amount, "no profit");
        } else {
            (dutchEtherResult, dutchTokenResult) = dutchXProxy.getCurrentAuctionPrice(token, dutchEther, dutchAuctionIndex);

            // buy uni sell dutch

            // uniswapPrice = uniswapTokensReturned / amount; // dai per ether
            // dutchPrice = dutchTokenResult / dutchEtherResult; // dai per ether
            // if (dutchPrice > uniswapPrice) {
            // if ((num1 * den2) > (num2 * den1)) {
            if ((dutchTokenResult * amount) > (uniswapTokensReturned * dutchEtherResult)) {

                // could also exchage some amt of wrapped Ether for Eth here.
                require(msg.value == amount, "buying from uniswap takes real Ether");
                uint256 minimumTokensExpectedFromDutch = (dutchTokenResult * amount) / dutchEtherResult;
                uint256 tokensBought = UniswapExchangeInterface(uniswapExchangeToken).ethToTokenSwapInput.value(amount)(minimumTokensExpectedFromDutch, block.timestamp);
                uint256 etherReturned;
                (dutchAuctionIndex, etherReturned) = dutchXProxy.postSellOrder(token, dutchEther, dutchAuctionIndex, tokensBought);

                // this one is greater than or equal to because the dutch results will only improve from there.
                require(etherReturned >= amount, "no profit");

            } else {
                // might need to remove this revert for the situation where an
                // estimateGas call will show a fail when in fact the trade would
                // succeed when actually executed...
                revert("not a good trade");
            }
        }
    }
}