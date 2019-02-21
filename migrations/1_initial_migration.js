var Migrations = artifacts.require("./Migrations.sol");

module.exports = function(deployer) {
  console.log('skip')
  return
  deployer.deploy(Migrations);
};
