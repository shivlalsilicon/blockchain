App = {
  web3Provider: null,
  contracts: {},

  init: async function () {
    // Load Products.
    $.getJSON("../pets.json", function (data) {
      var petsRow = $("#petsRow");
      var petTemplate = $("#petTemplate");

      for (i = 0; i < data.length; i++) {
        petTemplate.find(".panel-title").text(data[i].name);
        petTemplate.find("img").attr("src", data[i].picture);
        petTemplate.find(".pet-breed").text(data[i].breed);
        petTemplate.find(".pet-age").text(data[i].age);
        petTemplate.find(".pet-location").text(data[i].location);
        petTemplate.find(".btn-adopt").attr("data-id", data[i].id);

        petsRow.append(petTemplate.html());
      }
    });

    return await App.web3Connection();
    //return await App.initWeb3();
  },

  web3Connection: async function () {
    if (window.ethereum) {
      App.web3Provider = window.ethereum;
      try {
        
        // Request account access
        await window.ethereum.enable();
      } catch (error) {
        // User denied account access...
        console.error("User denied account access");


      }
    }
    // Legacy dapp browsers...
    else if (window.web3) {
      App.web3Provider = window.web3.currentProvider;
       console.log("Web3Connection. dapp browser");
      
    }
    // If no injected web3 instance is detected, fall back to Ganache
    else {
      console.log("Web3Connection. Ganache");
      App.web3Provider = new Web3.providers.HttpProvider(
        "http://localhost:7545"
      );
    }
    web3 = new Web3(App.web3Provider);

      return App.loadContract();
  },

  loadContract: function () {
    $.getJSON("CryptoShop.json", function (data) {
      // Get the necessary contract artifact file and instantiate it with @truffle/contract
      var CryptoShopData = data;
      App.contracts.CryptoShop = TruffleContract(CryptoShopData);

      // Set the provider for our contract
      App.contracts.CryptoShop.setProvider(App.web3Provider);

      // Use our contract to retrieve and mark the adopted pets
      return App.markAdopted();

      // return App.markProducts();
    });

    return App.bindEvents();
  },

  bindEvents: function () {
    $(document).on("click", ".btn-adopt", App.handleAdopt);
  },

  markAdopted: function () {
    var ShopInstance;

    App.contracts.CryptoShop.deployed()
      .then(function (instance) {
        ShopInstance = instance;
     //    console.log(  ShopInstance.getProducts());
        return ShopInstance.getProducts.call();
      })
      .then(function (products) {

        console.log(products);
        // for (i = 0; i < adopters.length; i++) {
        //   if (adopters[i] !== "0x0000000000000000000000000000000000000000") {
        //     $(".panel-pet")
        //       .eq(i)
        //       .find("button")
        //       .text("Success")
        //       .attr("disabled", true);
        //   }
        // }
      })
      .catch(function (err) {
        console.log(err.message);
      });
  },


  handleAdopt: function (event) {
    event.preventDefault();

    var petId = parseInt($(event.target).data("id"));

    var adoptionInstance;

    web3.eth.getAccounts(function (error, accounts) {
      if (error) {
        console.log(error);
      }

      var account = accounts[0];

      App.contracts.Adoption.deployed()
        .then(function (instance) {
          adoptionInstance = instance;

          // Execute adopt as a transaction by sending account
          return adoptionInstance.adopt(petId, { from: account });
        })
        .then(function (result) {
          return App.markAdopted();
        })
        .catch(function (err) {
          console.log(err.message);
        });
    });
  },
};


$(function() {
  $(window).load(function() {
    App.init();
  });
});
