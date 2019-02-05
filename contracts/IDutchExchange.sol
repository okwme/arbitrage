pragma solidity ^0.5.0;

contract IDutchExchange {
    function claimBuyerFunds(address, address, address, uint) public returns(uint, uint);
    function ethToken() public returns(address);
    function deposit(address tokenAddress, uint amount) public returns (uint);
    function withdraw(address tokenAddress, uint amount) public returns (uint);
    function getAuctionIndex(address token1, address token2) public returns(uint256);
    function postBuyOrder(address token1, address token2, uint256 auctionIndex, uint256 amount) public returns(uint256);
    function postSellOrder(address token1, address token2, uint256 auctionIndex, uint256 tokensBought) public returns(uint256, uint256);
    function getCurrentAuctionPrice(address token1, address token2, uint256 auctionIndex) public view returns(uint256, uint256);
    function claimAndWithdrawTokensFromSeveralAuctionsAsBuyer(address[] calldata, address[] calldata, uint[] calldata) external view returns(uint[] memory, uint);
}