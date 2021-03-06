(function() {
    "use strict";

    angular
        .module("spa-demo.subjects")
        .component("sdTypeSelector", {
            templateUrl: typeSelectorTemplateUrl,
            controller: TypeSelectorController,
            bindings: {
                authz: "<"
            }
        })
        .component("sdTypeEditor", {
            templateUrl: typeEditorTemplateUrl,
            controller: TypeEditorController,
            bindings: {
                authz: "<"
            },
            require: {
                typesAuthz: "^sdTypesAuthz"
            }
        });


    typeSelectorTemplateUrl.$inject = ["spa-demo.config.APP_CONFIG"];

    function typeSelectorTemplateUrl(APP_CONFIG) {
        return APP_CONFIG.type_selector_html;
    }

    typeEditorTemplateUrl.$inject = ["spa-demo.config.APP_CONFIG"];

    function typeEditorTemplateUrl(APP_CONFIG) {
        return APP_CONFIG.type_editor_html;
    }

    TypeSelectorController.$inject = ["$scope",
        "$stateParams",
        "spa-demo.authz.Authz",
        "spa-demo.subjects.Type"];

    function TypeSelectorController($scope, $stateParams, Authz, Type) {
        var vm=this;

        vm.$onInit = function() {
            console.log("TypeSelectorController",$scope);
            $scope.$watch(function(){ return Authz.getAuthorizedUserId(); },
                function(){
                    if (!$stateParams.id) {
                        if (Authz.isAuthenticated()) {
                            vm.items = Type.query();
                        }
                    }
                });
        }
        return;
        //////////////
    }

    TypeEditorController.$inject = ["$scope","$q",
        "$state", "$stateParams",
        "spa-demo.authz.Authz",
        "spa-demo.subjects.Type"
        // "spa-demo.subjects.TypeThing",
        // "spa-demo.subjects.TypeLinkableThing",
    ];

    function TypeEditorController($scope, $q, $state, $stateParams,
                                   Authz, Type) { // , TypeThing,TypeLinkableThing
        var vm=this;
        vm.selected_linkables=[];
        vm.create = create;
        vm.clear  = clear;
        vm.update  = update;
        vm.remove  = remove;
        // vm.linkThings = linkThings;

        vm.$onInit = function() {
            console.log("TypeEditorController",$scope);
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
            console.log("newResource()");
            vm.item = new Type();
            vm.typesAuthz.newItem(vm.item);
            return vm.item;
        }

        function reload(typeId) {
            var itemId = typeId ? typeId : vm.item.id;
            console.log("re/loading type", itemId);
            vm.item = Type.get({id:itemId});
            // vm.things = TypeThing.query({type_id:itemId});
            // vm.linkable_things = TypeLinkableThing.query({type_id:itemId});
            vm.typesAuthz.newItem(vm.item);
            $q.all([vm.item.$promise]).catch(handleError);
            // $q.all([vm.item.$promise, vm.things.$promise]).catch(handleError);
        }

        function clear() {
            newResource();
            $state.go(".", {id:null});
        }

        function create() {
            vm.item.$save().then(
                function(){
                    $state.go(".", {id: vm.item.id});
                },
                handleError);
        }

        function update() {
            vm.item.errors = null;
            var update=vm.item.$update();
            linkThings(update);
        }

        // function linkThings(parentPromise) {
        //     var promises=[];
        //     if (parentPromise) { promises.push(parentPromise); }
        //     angular.forEach(vm.selected_linkables, function(linkable){
        //         var resource=TypeThing.save({type_id:vm.item.id}, {thing_id:linkable});
        //         promises.push(resource.$promise);
        //     });
        //
        //     vm.selected_linkables=[];
        //     console.log("waiting for promises", promises);
        //     $q.all(promises).then(
        //         function(response){
        //             console.log("promise.all response", response);
        //             $scope.typeform.$setPristine();
        //             reload();
        //         },
        //         handleError);
        // }

        function remove() {
            vm.item.errors = null;
            vm.item.$delete().then(
                function(){
                    console.log("remove complete", vm.item);
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
            $scope.typeform.$setPristine();
        }
    }
})();
