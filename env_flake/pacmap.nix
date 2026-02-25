{ lib
, buildPythonPackage
, fetchPypi
, pytestCheckHook

# build dependencies
, setuptools

# dependencies
, annoy
, numpy
, numba
, scikit-learn
# test time dependencies
# , matplotlib
}:

buildPythonPackage rec {
  pname = "pacmap";
  version = "0.8.0";
  pyproject = true;

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-HAwQGA42t39eU0TYONAg3ZVXrBynfwl2wuMIZDsBkIQ=";
  };

  dependencies = [
    annoy
    numpy
    numba
    scikit-learn
  ];

  build-system = [ setuptools ];

  # nativeCheckInputs = [ 
  #   pytestCheckHook
  #   matplotlib
  # ];

  doCheck = true;
  
  pythonImportsCheck = [ "pacmap" ];

  meta = with lib; {
    description = "A dimensionality reduction method";
    homepage = "https://github.com/YingfanWang/PaCMAP";
    license = licenses.asl20;
  };
}