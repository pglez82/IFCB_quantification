var app = angular.module('MyApp', ['ngMaterial', 'plotly', 'ngSanitize','md.data.table']);

/*
 * This service loads all the data. The data loading is done at the beginning.
 */
app.service('DataLoadService', ['$q', function ($q)
    {
        /*
         * Loads the data using the promise pattern. One promise for each csv (one
         * for each class and for each attribute set)
         */
        this.loadData = function (classes, attribute_sets, quant_methods, progressCallBack)
        {
            progress = 0;
            maxprogress = attribute_sets.length * classes.length;
            base_path = "data/"
            var promises = [];

            //Add the trace for the autoclass. This is only one trace
            //path_autoclass = 'data/autoclass/';

            angular.forEach(classes, function (cl)
            {
                angular.forEach(attribute_sets, function (attset, index)
                {
                    path = base_path.concat(attset).concat('/predictions/').concat(cl).concat('.csv');
                    var deffered = $q.defer();
                    loadSingleFile(path, attset, quant_methods, index === 0).then(function (data) {
                        progressCallBack(++progress * 100 / maxprogress);
                        deffered.resolve(data);
                    });
                    promises.push(deffered.promise);
                });
            });
            return $q.all(promises);
        };

        /*
         * This function loads a single file. It uses plotly in order to load data
         * async from server.
         */
        function loadSingleFile(path, sufix, quant_methods, includeTrue)
        {
            return $q(function (resolve, reject) {
                Plotly.d3.csv(path,
                        function (data)
                        {
                            resolve(processData(data, sufix, quant_methods, includeTrue));
                        }
                );
            });
        }

        /*function loadSingleFileAutoClass(path)
        {
            return $q(function (resolve, reject) {
                Plotly.d3.csv(path,
                        function (data)
                        {
                            resolve(processDataAutoClass(data));
                        }
                );
            });
        }*/

        //This is called for each class and each attribute set
        function processData(allRows, sett, quant_methods, includeTrue)
        {
            r = {};
            r['x'] = [];
            r['t'] = [];
            for (var i = 0; i < quant_methods.length; i++)
                r[quant_methods[i]] = [];

            for (var i = 0; i < allRows.length; i++) {
                row = allRows[i];
                r['x'].push(row['']); //X axis
                r['t'].push(row['True']); //True prevalence
                for (var j = 0; j < quant_methods.length; j++) //Quantification methods
                    r[quant_methods[j]].push(row[quant_methods[j]]);
            }
            //TODO: un problema con los colores. No los deberíamos de generar aquí
            traces = [];
            if (includeTrue)
                traces.push({x: r['x'], y: r['t'], type: 'scatter', name: 'True'});
            for (var i = 0; i < quant_methods.length; i++)
                traces.push({x: r['x'], y: r[quant_methods[i]], type: 'scatter', name: quant_methods[i].concat("_").concat(sett), visible: 'legendonly', method: quant_methods[i], set: sett});

            return traces;
        }

        /*function processDataAutoClass(allRows)
        {
            var x = [], a = [];
            var color = "#3b3eac";

            for (var i = 0; i < allRows.length; i++) {
                row = allRows[i];
                x.push(row['']);
                a.push(row['AutoClass']);
            }
            var traceAutoClass = {x: x, y: a, type: 'scatter', name: "AutoClass", visible: 'legendonly', line: {color: color}};
            return [traceAutoClass];
        }*/
    }]);

/*
 * Service that process data. It has two functions. One for normalize the data
 * and one for computing errors.
 */
app.service('DataProcessService', function ()
{
    this.normalizeData = function (data_raw, classes)
    {
        dn = angular.copy(data_raw);
        sumMethods = {};
        angular.forEach(classes, function (cl)
        {
            for (i = 0; i < data_raw[cl].length; i++)
            {
                method = data_raw[cl][i];
                if (method.name !== "True")
                {
                    if (!(method.name in sumMethods))
                    {
                        sumMethods[method.name] = [];
                        for (j = 0; j < method.y.length; j++)
                            sumMethods[method.name][j] = parseFloat(method.y[j]);
                    } else
                        for (j = 0; j < sumMethods[method.name].length; j++)
                            sumMethods[method.name][j] = parseFloat(sumMethods[method.name][j]) + parseFloat(method.y[j]);
                }
            }
            ;
        });

        angular.forEach(classes, function (cl)
        {
            for (i = 0; i < data_raw[cl].length; i++)
            {
                method = data_raw[cl][i];
                if (method.name !== "True")
                {
                    for (j = 0; j < sumMethods[method.name].length; j++)
                        dn[cl][i].y[j] = dn[cl][i].y[j] / sumMethods[method.name][j];
                }
            }
        });
        return dn;
    };

    this.computeErrors = function (dat, classes, quant_methods, attribute_sets)
    {
        var ae = {};
        var re = {};

        epsilon = 1 / (2 * 3600.0);


        angular.forEach(classes, function (cl)
        {
            ae[cl] = {};
            re[cl] = {};

            //We use map because we want to preserve order in properties
            ae[cl].methods = {};
            re[cl].methods = {};


            //Initialize error values
            for (i=0;i<quant_methods.length;i++)
            {
                ae[cl].methods[quant_methods[i]] = {};
                re[cl].methods[quant_methods[i]] = {};
                for (j=0;j<attribute_sets.length;j++)
                {
                    ae[cl].methods[quant_methods[i]][attribute_sets[j]]=0;
                    re[cl].methods[quant_methods[i]][attribute_sets[j]]=0;
                }
            }

            ae_min_error = Number.MAX_VALUE;
            re_min_error = Number.MAX_VALUE;

            //All methods except the first which is true prevalence
            for (i = 1; i < dat[cl].length; i++)
            {
                method = dat[cl][i].method;
                set = dat[cl][i].set;

                ae[cl].methods[method][set] = 0;
                re[cl].methods[method][set] = 0;

                for (j = 0; j < dat[cl][i].y.length; j++)
                {
                    ae[cl].methods[method][set] += Math.abs(dat[cl][i].y[j] - dat[cl][0].y[j]);
                    re[cl].methods[method][set] += ((Math.abs(dat[cl][i].y[j] - dat[cl][0].y[j])) + epsilon) / (parseFloat(dat[cl][0].y[j]) + epsilon);
                }
                ae[cl].methods[method][set] /= dat[cl][i].y.length;
                re[cl].methods[method][set] /= dat[cl][i].y.length;
                if (ae[cl].methods[method][set] < ae_min_error)
                {
                    ae_min_error = ae[cl].methods[method][set];
                    ae[cl].best = dat[cl][i].name;
                }
                if (re[cl].methods[method][set] < re_min_error)
                {
                    re_min_error = re[cl].methods[method][set];
                    re[cl].best = dat[cl][i].name;
                }

            }
        });
        errors = {};
        errors.ae = ae;
        errors.re = re;
        return errors;
    };
});

/*
 * Main controller of the app.
 */
app.controller('MyController', ['$scope', 'DataLoadService', 'DataProcessService', '$mdDialog', function ($scope, DataLoadService, DataProcessService, $mdDialog) {

        $scope.classes = ['Asterionellopsis', 'bad', 'Cerataulina', 'Ceratium', 'Chaetoceros', 'ciliate_mix', 'clusterflagellate', 'Corethron', 'Coscinodiscus', 'Cylindrotheca', 'DactFragCerataul', 'Dactyliosolen', 'detritus', 'Dictyocha', 'dino30', 'Dinobryon', 'Dinophysis', 'Ditylum', 'Ephemera', 'Eucampia', 'Euglena', 'Guinardia', 'Guinardia_flaccida', 'Guinardia_striata', 'Gyrodinium', 'kiteflagellates', 'Laboea', 'Lauderia', 'Leptocylindrus', 'Licmophora', 'mix', 'mix_elongated', 'Myrionecta', 'na', 'Odontella', 'Paralia', 'pennate', 'Phaeocystis', 'Pleurosigma', 'Prorocentrum', 'Pseudonitzschia', 'Pyramimonas', 'Rhizosolenia', 'Skeletonema', 'Stephanopyxis', 'Thalassionema', 'Thalassiosira', 'Thalassiosira_dirty', 'tintinnid'];
        //Extra 'DFFT_resnet18_partial',,
        $scope.attribute_sets = ['NF','DF_resnet18','DF_resnet34','DFFT_resnet18_full', 'DFFT_resnet34_full', 'DFFT_resnet50_full','DFFT_resnet101_full'];
        var data_raw = {};
        var data_norm = {};
        var errors = {};
        $scope.selectedComp = 'atts';
        $scope.quantmethods = ['CC', 'AC', 'PCC', 'PAC', 'HDy', 'EM'];
        $scope.selectedMethod = 'CC';
        $scope.selectedSet = 'NF';

        DataLoadService.loadData($scope.classes, $scope.attribute_sets, $scope.quantmethods, function (percentage) {
            $scope.progress = Math.round(percentage);
        }).then(function (response) {
            for (var i = 0; i < $scope.classes.length; i++)
            {
                data_raw[$scope.classes[i]] = [];
                for (var j = 0; j < $scope.attribute_sets.length; j++)
                    data_raw[$scope.classes[i]] = data_raw[$scope.classes[i]].concat(response[(i * $scope.attribute_sets.length) + j]);
            }
            //In data_raw we have an object with a property for each class. In each class we have all the traces.
            data_norm = DataProcessService.normalizeData(data_raw, $scope.classes);
            errors = DataProcessService.computeErrors(data_norm, $scope.classes,$scope.quantmethods,$scope.attribute_sets);
            $scope.dataloaded = true;
        });

        $scope.selectOption = function () {
            makeplot($scope.selectedClass, $scope.normalized, $scope.selectedComp, $scope.selectedMethod, $scope.selectedSet);
            $scope.errors_ae = errors.ae[$scope.selectedClass];
            $scope.errors_re = errors.re[$scope.selectedClass];

        };

        function makeplot(cl, normalized, selectedComp, selectedMethod, selectedSet) {
            if (normalized)
                data_used = data_norm;
            else
                data_used = data_raw;

            $scope.data = [];
            $scope.data.push(data_used[cl][0]);
            $scope.layout = {xaxis: {title: 'File'}};
            //We have to take only the traces needed
            for (var i = 1; i < data_used[cl].length; i++)
            {
                if (selectedComp === 'atts') //Show selectedMethod for all the sets
                {
                    if (data_used[cl][i].method === selectedMethod)
                        $scope.data.push(data_used[cl][i]);
                } else if (selectedComp === 'meths') //Show selectedMethod for all the sets
                {
                    if (data_used[cl][i].set === selectedSet)
                        $scope.data.push(data_used[cl][i]);
                }
            }

            //Assign colors
            var colors = ["#3366cc", "#dc3912", "#ff9900", "#109618", "#990099", "#0099c6", "#dd4477", "#66aa00", "#b82e2e", "#316395", "#994499", "#22aa99", "#aaaa11", "#6633cc", "#e67300", "#8b0707", "#651067", "#329262", "#5574a6", "#3b3eac"];
            for (var i = 0; i < $scope.data.length; i++)
                $scope.data[i].line = {color: colors[i]}

            $scope.options = {showLink: false, displayLogo: false};
        }

        $scope.resetChart = function () {
            for (var i = 0; i < $scope.data.length; i++)
            {
                if ($scope.data[i].name === 'True')
                    $scope.data[i].visible = true;
                else
                    $scope.data[i].visible = 'legendonly';
            }
        };
        $scope.changeNormalized = function ()
        {
            makeplot($scope.selectedClass, $scope.normalized, $scope.selectedComp, $scope.selectedMethod, $scope.selectedSet);
        };

        $scope.init = function ()
        {
            $scope.dataloaded = false;
            $scope.normalized = true;
            $scope.progress = 0;
        };


        $scope.showInfoDialog = function (ev) {
            $mdDialog.show({
                controller: DialogController,
                templateUrl: 'helpdialog.tmpl.html',
                parent: angular.element(document.body),
                targetEvent: ev,
                clickOutsideToClose: true,
                fullscreen: true
            });
        };

        function DialogController($scope, $mdDialog) {
            $scope.hide = function () {
                $mdDialog.hide();
            };

            $scope.cancel = function () {
                $mdDialog.cancel();
            };
        }

        /*$scope.showBestMethod = function ()
        {
            for (var i = 0; i < $scope.data.length; i++)
            {
                if ($scope.data[i].name === 'True' || $scope.data[i].name === 'CC_NF' || $scope.data[i].name === $scope.errors_ae.best)
                    $scope.data[i].visible = true;
                else
                    $scope.data[i].visible = 'legendonly';
            }
        };*/

    }]);
