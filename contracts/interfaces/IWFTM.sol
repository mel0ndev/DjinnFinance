pragma solidity >=0.5.0; 


interface IWFTM {
	function deposit() external payable returns(uint256); 
	function withdraw(uint256 amount) external returns(uint256); 
}
