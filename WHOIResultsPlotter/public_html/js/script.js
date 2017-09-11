var app = angular.module('MyApp', ['ngMaterial', 'plotly','ngSanitize']);

app.service('DataLoadService', ['$q', function ($q)
{
    this.loadData = function (classes,progressCallBack)
    {
        progress = 0;
        maxprogress = 4*classes.length;
        path_nf = 'data/OneVsAll1vs50/';
        path_df = 'data/OneVsAll1vs50DL/';
        path_dfft = 'data/OneVsAll1vs50DLFT/';

        var promises = [];
        
        //Add the trace for the autoclass. This is only one trace
        path_autoclass = 'data/autoclass/';
        

        angular.forEach(classes,function(cl)
        {
            nf=path_nf.concat('predictions/').concat(cl).concat('.csv');
            df=path_df.concat('predictions/').concat(cl).concat('.csv');
            dfft=path_dfft.concat('predictions/').concat(cl).concat('.csv');
            autoclass=path_autoclass.concat(cl).concat('.csv');
            
            var deffered1 = $q.defer();
            loadSingleFile(nf,"_NF",true).then(function(data){
                progressCallBack(++progress*100/maxprogress);
                deffered1.resolve(data);
            });
            promises.push(deffered1.promise);
            var deffered2 = $q.defer();
            loadSingleFile(df,"_DF",false).then(function(data){
                progressCallBack(++progress*100/maxprogress);
                deffered2.resolve(data);
            });
            promises.push(deffered2.promise);
            var deffered3 = $q.defer();
            loadSingleFile(dfft,"_DFFT",false).then(function(data){
                progressCallBack(++progress*100/maxprogress);
                deffered3.resolve(data);
            });
            promises.push(deffered3.promise);
            var deffered4 = $q.defer();
            loadSingleFileAutoClass(autoclass).then(function(data){
                progressCallBack(++progress*100/maxprogress);
                deffered4.resolve(data);
            });
            promises.push(deffered4.promise);
        });
        return $q.all(promises);   
    };

    function loadSingleFile(path,sufix,includeTrue)
    {
        return $q(function (resolve, reject) {
            Plotly.d3.csv(path,
                        function (data)
                        {
                            resolve(processData(data,sufix,includeTrue));
                        }
                );
        });
    }
    
    function loadSingleFileAutoClass(path)
    {
        return $q(function (resolve, reject) {
            Plotly.d3.csv(path,
                        function (data)
                        {
                            resolve(processDataAutoClass(data));
                        }
                );
        });
    }

    function processData(allRows,sufix,includeTrue)
    {
        var x = [], t = [], cc = [],ac = [],pcc=[],pac=[],HDy=[],em=[];
        var colors = ["#3366cc", "#dc3912", "#ff9900", "#109618", "#990099", "#0099c6", "#dd4477", "#66aa00", "#b82e2e", "#316395", "#994499", "#22aa99", "#aaaa11", "#6633cc", "#e67300", "#8b0707", "#651067", "#329262", "#5574a6", "#3b3eac"];
        
        //For generating different colors
        if (sufix==='_NF') order = 0;
        if (sufix==='_DF') order = 1;
        if (sufix==='_DFFT') order = 2;

        for (var i = 0; i < allRows.length; i++) {
            row = allRows[i];
            x.push(row['']);
            t.push(row['True']);
            cc.push(row['CC']);
            ac.push(row['AC']);
            pcc.push(row['PCC']);
            pac.push(row['PAC']);
            HDy.push(row['HDy']);
            em.push(row['EM']);
        }
        var traceTrue = {x: x,y: t,type: 'scatter',name: 'True',line: {color: colors[0]}};
        var traceCC = {x: x,y: cc,type: 'scatter',name: "CC".concat(sufix),visible:'legendonly',line: {color: colors[1+(order*6)]}};
        var traceAC = {x: x,y: ac,type: 'scatter',name: 'AC'.concat(sufix),visible:'legendonly',line: {color: colors[2+(order*6)]}};
        var tracePCC = {x: x,y: pcc,type: 'scatter',name: 'PCC'.concat(sufix),visible:'legendonly',line: {color: colors[3+(order*6)]}};
        var tracePAC = {x: x,y: pac,type: 'scatter',name: 'PAC'.concat(sufix),visible:'legendonly',line: {color: colors[4+(order*6)]}};
        var traceHDy = {x: x,y: HDy,type: 'scatter',name: 'HDy'.concat(sufix),visible:'legendonly',line: {color: colors[5+(order*6)]}};
        var traceEM = {x: x,y: em,type: 'scatter',name: 'EM'.concat(sufix),visible:'legendonly',line: {color: colors[6+(order*6)]}};

        if (includeTrue)
            return [traceTrue, traceCC,traceAC,tracePCC,tracePAC,traceHDy,traceEM];
        else
            return [traceCC,traceAC,tracePCC,tracePAC,traceHDy,traceEM];
    }
    
    function processDataAutoClass(allRows)
    {
        var x = [], a=[];
        var color = "#3b3eac";
        
        for (var i = 0; i < allRows.length; i++) {
            row = allRows[i];
            x.push(row['']);
            a.push(row['AutoClass']);
        }
        var traceAutoClass = {x: x,y: a,type: 'scatter',name: "AutoClass",visible:'legendonly',line: {color: color}};
        return [traceAutoClass];
    }
}]);
    
    
app.service('DataProcessService', function ()
{
    this.normalizeData = function(data_raw,classes)
    {
        dn = angular.copy(data_raw);
        sumMethods = {};
        angular.forEach(classes,function(cl)
        {
            for (i=0;i<data_raw[cl].length;i++)
            {
                method = data_raw[cl][i];
                if (method.name!=="True")
                {
                    if (!(method.name in sumMethods))
                    {
                        sumMethods[method.name] = [];
                        for (j=0;j<method.y.length;j++)
                            sumMethods[method.name][j]=parseFloat(method.y[j]);
                    }
                    else
                        for (j=0;j<sumMethods[method.name].length;j++)
                            sumMethods[method.name][j]=parseFloat(sumMethods[method.name][j])+parseFloat(method.y[j]);
                }
            };
        });

        angular.forEach(classes,function(cl)
        {
            for (i=0;i<data_raw[cl].length;i++)
            {
                method = data_raw[cl][i];
                if (method.name!=="True")
                {
                    for (j=0;j<sumMethods[method.name].length;j++)
                        dn[cl][i].y[j] = dn[cl][i].y[j]/sumMethods[method.name][j];
                }
            }
        });
        return dn;
    };
        
    this.computeErrors = function(dat,classes)
    {
        var ae={};
        var re={};
        var methods = [];
        epsilon = 1/(2*3600.0);

        for (i=1;i<dat[classes[0]].length;i++)
            methods.push(dat[classes[0]][i].name);

        angular.forEach(classes,function(cl)
        {
            ae[cl] = {};
            re[cl] = {};
            ae[cl].methods = {};
            re[cl].methods = {};
            
            ae_min_error = Number.MAX_VALUE;
            re_min_error = Number.MAX_VALUE;
            
            //All methods except the first which is true prevalence
            for (i=1;i<dat[cl].length;i++)
            {
                ae[cl].methods[dat[cl][i].name]=0;
                re[cl].methods[dat[cl][i].name]=0;
                
                for (j=0;j<dat[cl][i].y.length;j++)
                {
                    ae[cl].methods[dat[cl][i].name]+=Math.abs(dat[cl][i].y[j]-dat[cl][0].y[j]);
                    re[cl].methods[dat[cl][i].name]+=((Math.abs(dat[cl][i].y[j]-dat[cl][0].y[j]))+epsilon)/(parseFloat(dat[cl][0].y[j])+epsilon);
                }
                ae[cl].methods[dat[cl][i].name]/=dat[cl][i].y.length;
                re[cl].methods[dat[cl][i].name]/=dat[cl][i].y.length;
                if (ae[cl].methods[dat[cl][i].name]<ae_min_error)
                {
                    ae_min_error = ae[cl].methods[dat[cl][i].name];
                    ae[cl].best = dat[cl][i].name;
                }
                if (re[cl].methods[dat[cl][i].name]<re_min_error)
                {
                    re_min_error = re[cl].methods[dat[cl][i].name];
                    re[cl].best = dat[cl][i].name;
                }
                
            }
        });
        errors = {};
        errors.ae = ae;
        errors.re = re;
        errors.methods = methods;
        return errors;
    };
});

app.controller('MyController', ['$scope','DataLoadService','DataProcessService','$mdDialog', function ($scope, DataLoadService,DataProcessService,$mdDialog) {
        
    $scope.classes = ['Asterionellopsis','bad','Cerataulina','Ceratium','Chaetoceros','ciliate_mix','clusterflagellate','Corethron','Coscinodiscus','Cylindrotheca','DactFragCerataul','Dactyliosolen','detritus','Dictyocha','dino30','Dinobryon','Dinophysis','Ditylum','Ephemera','Eucampia','Euglena','Guinardia','Guinardia_flaccida','Guinardia_striata','Gyrodinium','kiteflagellates','Laboea','Lauderia','Leptocylindrus','Licmophora','mix','mix_elongated','Myrionecta','na','Odontella','Paralia','pennate','Phaeocystis','Pleurosigma','Prorocentrum','Pseudonitzschia','Pyramimonas','Rhizosolenia','Skeletonema','Stephanopyxis','Thalassionema','Thalassiosira','Thalassiosira_dirty','tintinnid'];
    var data_raw = {};
    var data_norm = {};
    var errors = {};

    DataLoadService.loadData($scope.classes,function(percentage){
        $scope.progress=Math.round(percentage);
    }).then(function (response) {
        for (var i=0;i<$scope.classes.length;i++)
            data_raw[$scope.classes[i]] = response[i*4].concat(response[(i*4)+1]).concat(response[(i*4)+2]).concat(response[(i*4)+3]);

        //In data_raw we have an object with a property for each class. In each class we have all the traces.
        data_norm=DataProcessService.normalizeData(data_raw,$scope.classes);
        errors = DataProcessService.computeErrors(data_norm,$scope.classes);
        $scope.methods = errors.methods;
        $scope.dataloaded = true;
    });

    $scope.selectOption = function () {
        makeplot($scope.selectedClass,$scope.normalized);
        $scope.errors_ae = errors.ae[$scope.selectedClass];
        $scope.errors_re = errors.re[$scope.selectedClass];

    };

    function makeplot(cl,normalized) {
        if (normalized)
        {
            $scope.data = data_norm[cl];
            $scope.layout = {xaxis:{title:'File'}}; 
        }
        else
        {
            $scope.data = data_raw[cl];
            $scope.layout = {xaxis:{title:'File'}};
        }    

        $scope.options = {showLink: false,displayLogo: false};
    }

    $scope.resetChart = function() {
        for (var i=0;i<$scope.data.length;i++)
        {
            if ($scope.data[i].name==='True')
                $scope.data[i].visible=true;
            else
                $scope.data[i].visible='legendonly';
        }
    };
    $scope.changeNormalized=function()
    {
        makeplot($scope.selectedClass,$scope.normalized); 
    };

    $scope.init=function()
    {
        $scope.dataloaded = false;
        $scope.normalized = true;
        $scope.progress = 0;
    };


    $scope.showInfoDialog = function(ev) {
        $mdDialog.show({
            controller: DialogController,
            templateUrl: 'helpdialog.tmpl.html',
            parent: angular.element(document.body),
            targetEvent: ev,
            clickOutsideToClose:true,
            fullscreen: true
        });
      };
      
    function DialogController($scope, $mdDialog) {
        $scope.hide = function() {
          $mdDialog.hide();
        };

        $scope.cancel = function() {
          $mdDialog.cancel();
        };
      }
      
      $scope.showBestMethod=function()
      {
            for (var i=0;i<$scope.data.length;i++)
            {
                if ($scope.data[i].name==='True' || $scope.data[i].name==='CC_NF' || $scope.data[i].name===$scope.errors_ae.best)
                    $scope.data[i].visible=true;
                else
                    $scope.data[i].visible='legendonly';
            }
      };
        
    }]);
