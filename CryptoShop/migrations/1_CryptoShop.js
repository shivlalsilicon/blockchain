const Cryptoshop = artifacts.require("CryptoShop");

module.exports = function(deployer) {
   deployer.deploy(Cryptoshop);
};
