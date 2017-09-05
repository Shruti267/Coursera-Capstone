(function() {
  "use strict";

  angular
    .module("spa-demo.subjects")
    .component("sdThingEditor", {
      templateUrl: thingEditorTemplateUrl,
      controller: ThingEditorController,
      bindings: {
        authz: "<"
      },
      require: {
        thingsAuthz: "^sdThingsAuthz"
      }      
    })
    .component("sdThingSelector", {
      templateUrl: thingSelectorTemplateUrl,
      controller: ThingSelectorController,
      bindings: {
        authz: "<"
      }
    })
    ;


  thingEditorTemplateUrl.$inject = ["spa-demo.config.APP_CONFIG"];
  function thingEditorTemplateUrl(APP_CONFIG) {
    return APP_CONFIG.thing_editor_html;
  }    
  thingSelectorTemplateUrl.$inject = ["spa-demo.config.APP_CONFIG"];
  function thingSelectorTemplateUrl(APP_CONFIG) {
    return APP_CONFIG.thing_selector_html;
  }    

  ThingEditorController.$inject = ["$scope","$q",
                                   "$state","$stateParams",
                                   "spa-demo.authz.Authz",
                                   "spa-demo.subjects.Thing",
                                   "spa-demo.subjects.ThingImage",
                                   "spa-demo.subjects.ThingType"];
  function ThingEditorController($scope, $q, $state, $stateParams, Authz, Thing, ThingImage, ThingType) {
    var vm=this;
    vm.create = create;
    vm.clear  = clear;
    vm.update  = update;
    vm.remove  = remove;
    vm.haveDirtyImageLinks = haveDirtyImageLinks;
    vm.haveDirtyTypeLinks = haveDirtyTypeLinks;
    vm.updateImageLinks = updateImageLinks;
    vm.updateTypeLinks = updateTypeLinks;

    vm.$onInit = function() {
      console.log("ThingEditorController",$scope);
      $scope.$watch(function(){ return Authz.getAuthorizedUserId(); }, 
                    function(){ 
                      if ($stateParams.id) {
                        reload($stateParams.id); 
                      } else {
                        newResource();
                      }
                    });
    }

    return;
    //////////////
    function newResource() {
      vm.item = new Thing();
      vm.thingsAuthz.newItem(vm.item);
      return vm.item;
    }

    function reload(thingId) {
      var itemId = thingId ? thingId : vm.item.id;      
      console.log("re/loading thing", itemId);
      vm.images = ThingImage.query({thing_id:itemId});
      vm.types = ThingType.query({ thing_id: itemId });
      vm.item = Thing.get({id:itemId});
      vm.thingsAuthz.newItem(vm.item);
      vm.images.$promise.then(
        function(){
          angular.forEach(vm.images, function(ti){
            ti.originalPriority = ti.priority;            
          });                     
        });
      vm.types.$promise.then(
        function(){
            angular.forEach(vm.types, function(tt){
                tt.originalIsVipPassRequired = tt.is_vip_pass_required;
            });
        });
      $q.all([vm.item.$promise,vm.images.$promise,,vm.types.$promise]).catch(handleError);
    }

    function haveDirtyImageLinks() {
      for (var i=0; vm.images && i<vm.images.length; i++) {
        var ti=vm.images[i];
        if (ti.toRemove || ti.originalPriority != ti.priority) {
          return true;
        }        
      }

      return false;
    }

      function haveDirtyTypeLinks() {
          for (var i=0; vm.types && i<vm.types.length; i++) {
              var tt=vm.types[i];
              if (tt.toRemove || tt.originalIsVipPassRequired != tt.is_vip_pass_required) {
                  return true;
              }
          }

          return false;
      }

    function create() {
      vm.item.errors = null;
      vm.item.$save().then(
        function(){
          console.log("thing created", vm.item);
          $state.go(".",{id:vm.item.id});
        },
        handleError);
    }

    function clear() {
      newResource();
      $state.go(".",{id: null});    
    }

    function update() {      
      vm.item.errors = null;
      var update=vm.item.$update();
      updateImageLinks(update);
      updateTypeLinks(update);
    }

    function updateImageLinks(promise) {
      console.log("updating links to images");
      var promises = [];
      if (promise) { promises.push(promise); }
      angular.forEach(vm.images, function(ti){
        if (ti.toRemove) {
          promises.push(ti.$remove());
        } else if (ti.originalPriority != ti.priority) {          
          promises.push(ti.$update());
        }
      });

      console.log("waiting for promises", promises);
      $q.all(promises).then(
        function(response){
          console.log("promise.all response", response); 
          //update button will be disabled when not $dirty
          $scope.thingform.$setPristine();
          reload(); 
        }, 
        handleError);    
    }

    function updateTypeLinks(promise) {
      console.log("updating links to types");
      var promises = [];
      if (promise) { promises.push(promise); }
      angular.forEach(vm.types, function(tt) {
        if (tt.toRemove) {
          promises.push(tt.$remove());
        } else if (tt.originalIsVipPassRequired != tt.is_vip_pass_required) {
          promises.push(tt.$update());
        }
      });

      console.log("waiting for promises", promises);
      $q.all(promises).then(
        function(response){
          console.log("promise.all response", response);
          //update button will be disabled when not $dirty
          $scope.thingform.$setPristine();
          reload();
        },
        handleError);
    }

    function remove() {
      vm.item.$remove().then(
        function(){
          console.log("thing.removed", vm.item);
          clear();
        },
        handleError);
    }

    function handleError(response) {
      console.log("error", response);
      if (response.data) {
        vm.item["errors"]=response.data.errors;          
      } 
      if (!vm.item.errors) {
        vm.item["errors"]={}
        vm.item["errors"]["full_messages"]=[response]; 
      }      
      $scope.thingform.$setPristine();
    }    
  }

  ThingSelectorController.$inject = ["$scope",
                                     "$stateParams",
                                     "spa-demo.authz.Authz",
                                     "spa-demo.subjects.Thing"];
  function ThingSelectorController($scope, $stateParams, Authz, Thing) {
    var vm=this;

    vm.$onInit = function() {
      console.log("ThingSelectorController",$scope);
      $scope.$watch(function(){ return Authz.getAuthorizedUserId(); }, 
                    function(){ 
                      if (!$stateParams.id) {
                        vm.items = Thing.query();        
                      }
                    });
    }
    return;
    //////////////
  }

})();
