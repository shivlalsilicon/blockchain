App = {
  web3Provider: null,
  contracts: {},

  init: async function () {
    await App.initWeb3();
    await App.initContract();
    await App.getProduct();
    await App.getOrders();
  },

  initWeb3: async function () {
    // Modern dapp browsers...
    if (window.ethereum) {
      App.web3Provider = window.ethereum;
      try {
        // Request account access
        await window.ethereum.enable();
      } catch (error) {
        // User denied account access
        console.error("User denied account access");
      }
      console.info("Modern dapp browsers...");
    }
    // Legacy dapp browsers...
    else if (window.web3) {
      App.web3Provider = window.web3.currentProvider;
      console.info("Legacy dapp browsers...");
    }
    // If no injected web3 instance is detected, fall back to Ganache
    else {
      App.web3Provider = new Web3.providers.HttpProvider(
        "http://localhost:7545"
      );

      console.info("http://localhost:7545");
    }

    web3 = new Web3(App.web3Provider);
  },

  initContract: async function () {
    json_file_name = "CryptoShop.json"; // get from build folder
    currencySymbol = "$";
    orderStatuses = [
      "Pending",
      "Processing",
      "Completed",
      "Cancelled",
      "Failed",
      "Onhold",
      "Refunded",
      "Deleted",
    ];

    $.getJSON(json_file_name)
      .done(function (data) {
        var Artifact = data;
        App.contracts.Adoption = TruffleContract(Artifact);

        // Set the provider for our contract
        App.contracts.Adoption.setProvider(App.web3Provider);
        App.contracts.currencySymbol = currencySymbol;
        App.contracts.orderStatuses = orderStatuses;
      })
      .fail(function () {
        console.log(json_file_name + " not found!");
      });
  },

  getProduct: async function () {
    try {
      web3.eth.getAccounts(function (error, accounts) {
        if (error) {
          console.log(error);
        }
        //console.log(accounts);
        var account = accounts[0];
        console.log("Current Account: "+account)

        App.contracts.Adoption.deployed()
          .then(function (CryptoShop) {
            return CryptoShop.getProducts();
          })
          .then(function (products) {
            App.contracts.products = products;
            var ProductRow = $("#productRow");
            var ProductTemplate = $("#productTemplate tbody");

            for (i = 0; i < products.length; i++) {
              pID = products[i]._product_id;
              productDescritpion = products[i]._product_description;
              productPrice = products[i]._product_price * 1;
              productPrice = productPrice.toFixed(2);
              PublishDate = products[i]._product_publish_date;
              Quantities = products[i]._product_quantities;
              ProductStatus = products[i]._product_status;
              ProductTitle = products[i]._product_title;
              ProductUpdatedDate = products[i]._product_updated_date;

              ProductTemplate.find(".productTitle").html(ProductTitle);

              ProductTemplate.find(".product_description").html(
                productDescritpion
              );

              ProductTemplate.find(".qty")
                .attr("data-id", pID)
                .removeClass()
                .addClass(" qty qty" + "_" + pID)
                .attr("max", Quantities);

              ProductTemplate.find(".product-price")
                .attr("data-id", pID)
                .attr("data-price", productPrice)
                .removeClass()
                .addClass("product-price product-price_" + pID)
                .html(productPrice);

              ProductTemplate.find(".product-total-price")
                .attr("data-id", pID)
                .removeClass()
                .addClass("product-total-price product-total-price_" + pID)
                .html("$" + "0.00");

              ProductRow.append(ProductTemplate.html());

              //remove classes after add
              if (i == products.length - 1) {
                ProductTemplate.find(".single_check").removeClass();
                ProductTemplate.find(".productTitle").removeClass();
                ProductTemplate.find(".qty").removeClass();
                ProductTemplate.find(".product-price").removeClass();
                ProductTemplate.find(".product-total-price").removeClass();
              }
            }

            App.addScript();
          })
          .catch(function (err) {
            console.log(err.message);
          });
      });
    } catch (error) {
      console.error(error);
    }
  },
  getOrders: async function () {
    try {
      web3.eth.getAccounts(function (error, accounts) {
        if (error) {
          console.log(error);
        }

        var account = accounts[0];
        App.contracts.Adoption.deployed()
          .then(function (CryptoShop) {
            return CryptoShop.getOrders(account);
          })
          .then(function (orders) {
            var OrderRow = $("#OrderRow");
            var OrderTemplate = $("#orderTemplate tbody");
            var products = App.contracts.products;
            var orderStatuses = App.contracts.orderStatuses;

            var currencySymbol = App.contracts.currencySymbol;
            var orderStatuseClasses = {
              Pending: "badge badge-secondary", //0
              Processing: "badge badge-primary", //1
              Completed: "badge badge-success", //2
              Cancelled: "badge badge-danger", //3
              Failed: "badge badge-dark", //4
              Onhold: "badge badge-info", //5
              Refunded: "badge badge-warning", //6
              Deleted: "badge badge-danger", //7
            };
            for (i = 0; i < orders.length; i++) {
              //debugger
              OrderID = orders[i]._order_id;
              OrderCustomer = orders[i]._customer;
              Order_date = orders[i]._date_of_purchase;
              _ord_date = new Date(Order_date * 1000);
              OrderDate = _ord_date.toLocaleString();
              OrderItemIds = orders[i]._ord_item_ids;
              OrderItemPrices = orders[i]._ord_item_prices;
              OrderItemQtys = orders[i]._ord_item_qty;
              OrderStatus = orderStatuses[orders[i]._status];
              OrderBilling = orders[i]._billing_address;
              OrderShipping = orders[i]._shipping_address;
              OrderTotal = orders[i]._purchase_total;
              OrderTotalProductCount = OrderItemIds.length;
              ItemNames = [];
              $inlineTable = "";
              for (j = 0; j < OrderItemIds.length; j++) {
                p_id = OrderItemIds[j] - 1;
                p_qtys = OrderItemQtys[j];
                p_price = OrderItemPrices[j];

                $inlineTable += "<p style='margin: 7px 0px;'>";
                $inlineTable +=
                  products[p_id]._product_title +
                  " (" +
                  p_price +
                  "*" +
                  p_qtys +
                  ")";
                $inlineTable += "</p>";

                //ItemNames.push('- '+products[p_id]._product_title + ' (' + p_price + '*' + p_qtys + ')');
              }
              // $inlineTable += "</table>";

              //  ItemNames = ItemNames.join('<br>');
              ItemNames = $inlineTable;
              OrderTemplate.find(".OrderID").html("#" + OrderID);
              OrderTemplate.find(".OrderCustomerID").html(1);
              OrderTemplate.find(".OrderDate").html(OrderDate);
              OrderTemplate.find(".OrderTotal").html(
                currencySymbol + "" + OrderTotal
              );
              OrderTemplate.find(".OrderItems").html(ItemNames);
              OrderTemplate.find(".OrderTotalItems").html(
                OrderTotalProductCount
              );
              OrderTemplate.find(".OrderStatus").html(
                "<span class='" +
                  orderStatuseClasses[OrderStatus] +
                  "'>" +
                  OrderStatus +
                  "</span>"
              );

              OrderRow.append(OrderTemplate.html());
            }
          })
          .catch(function (err) {
            console.log(err.message);
          });
      });
    } catch (error) {
      console.error(error);
    }
  },
  Checkout: async function (event) {
    event.preventDefault();

    var petId = 2;

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
          return adoptionInstance.createOrder(
            2400,
            "billing addr",
            "shipping addr",
            [1, 3],
            [3, 5],
            [500, 300],
            { from: account }
          );
        })
        .then(function (result) {
         // return App.markAdopted();
        })
        .catch(function (err) {
         // console.log(err.message);
        });
    });
  },
  addScript: function () {
    $(".sub").click(function () {
      var selectedInput = $(this).next("input");
      if (selectedInput.val() > 0) {
        selectedInput[0].stepDown(1);
        pID = selectedInput.data("id");
        pPrice = $(".product-price_" + pID).data("price");
        productTotalPrice =
          parseFloat(pPrice) * parseFloat(selectedInput.val());
        productTotalPrice = productTotalPrice.toFixed(2);
        totalVal = $(".total_val_" + pID).html(productTotalPrice);
        $(".total_val_hidden_" + pID).val(productTotalPrice);
        $(".product-total-price_" + pID)
          .attr("data-price", productTotalPrice)
          .html("$" + productTotalPrice);
        App.calculateTotal();
      }
    });

    $(".add").click(function () {
      var selectedInput = $(this).prev("input");
      if (selectedInput.val()) {
        selectedInput[0].stepUp(1);
        pID = selectedInput.data("id");
        pPrice = $(".product-price_" + pID).data("price");
        productTotalPrice =
          parseFloat(pPrice) * parseFloat(selectedInput.val());
        productTotalPrice = productTotalPrice.toFixed(2);
        totalVal = $(".total_val_" + pID).html(productTotalPrice);
        $(".total_val_hidden_" + pID).val(productTotalPrice);
        $(".product-total-price_" + pID)
          .attr("data-price", productTotalPrice)
          .html("$" + productTotalPrice);
        App.calculateTotal();
      }
    });

    $(".payment_btn").click(function (event) {
      return App.Checkout(event);
    });
  },

  calculateTotal: function () {
    var grandTotal = parseInt("0.00", 2);
    //grandTotal = grandTotal.toFixed(2);
    selectedProducts = $(".qty").filter(function () {
      return parseInt(this.value, 2) !== 0;
    });

    $.each(selectedProducts, function (key, value) {
      var classId = $(this).data("id");
      var qty = $(this).val();
      var itemPrice = $(".product-price_" + classId).data("price");
      var productTotal = qty * itemPrice;
      grandTotal += productTotal;
    });

    $(".final_total").data("price", grandTotal.toFixed(2));
    $(".final_total").html("<b>$" + grandTotal.toFixed(2) + "</b>");
  },
};

$(function () {
  $(window).on("load", function () {
      App.init();
  });
});
