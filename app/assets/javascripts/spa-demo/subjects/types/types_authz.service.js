(function() {
    "use strict";

    angular
        .module("spa-demo.subjects")
        .factory("spa-demo.subjects.TypesAuthz", TypesAuthzFactory);

    TypesAuthzFactory.$inject = ["spa-demo.authz.Authz",
        "spa-demo.authz.BasePolicy"];
    function TypesAuthzFactory(Authz, BasePolicy) {
        function TypesAuthz() {
            BasePolicy.call(this, "Type");
        }
        //start with base class prototype definitions
        TypesAuthz.prototype = Object.create(BasePolicy.prototype);
        TypesAuthz.constructor = TypesAuthz;


        //override and add additional methods
        TypesAuthz.prototype.canQuery = function() {
            console.log("TypesAuthz.canQuery", Authz.isAuthenticated());
            return Authz.isAuthenticated();
        };

        TypesAuthz.prototype.canGetDetails = function(item) {
            //console.log("TypesAuthz.canGetDetails", item);
            if (!item) {
                return false;
            } else {
                return !item.id ? this.canCreate() : Authz.isAuthenticated();
            }
        };

        // TypesAuthz.prototype.canCreate = function() {
        //     console.log("TypesAuthz.canCreate");
        //     return Authz.isOriginator(this.resourceName);
        // };

        // TypesAuthz.prototype.canUpdate = function(item) {
        //     console.log("TypesAuthz.canUpdate", item);
        //     if (!item) {
        //         return false;
        //     } else {
        //         return !item.id ? this.canCreate() : Authz.isOrganizer(item);
        //     }
        // };

        // TypesAuthz.prototype.canDelete = function(item) {
        //     console.log("TypesAuthz.canDelete", item);
        //     // return (item && item.id && (this.canUpdate(item) || Authz.isAdmin())) == true;
        //     return (item != null && item.id != null && this.canUpdate(item));
        // };

        return new TypesAuthz();
    }
})();