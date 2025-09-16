#!/usr/bin/env python3
"""
Test automation script for Crop Recommendation API
Runs all test suites with proper configuration and reporting
"""

import subprocess
import sys
import os
import argparse
import time
from pathlib import Path

def run_command(command, description):
    """Run a command and return success status"""
    print(f"\n{'='*60}")
    print(f"Running: {description}")
    print(f"Command: {command}")
    print(f"{'='*60}")
    
    start_time = time.time()
    result = subprocess.run(command, shell=True, capture_output=True, text=True)
    end_time = time.time()
    
    print(f"Exit code: {result.returncode}")
    print(f"Duration: {end_time - start_time:.2f} seconds")
    
    if result.stdout:
        print("STDOUT:")
        print(result.stdout)
    
    if result.stderr:
        print("STDERR:")
        print(result.stderr)
    
    return result.returncode == 0

def run_unit_tests():
    """Run unit tests"""
    command = "python -m pytest tests/test_ultra_fast_api.py tests/test_data_management.py -v --cov=ultra_fast_api --cov=data_management_system --cov=performance_optimizer --cov-report=html:htmlcov --cov-report=term-missing"
    return run_command(command, "Unit Tests")

def run_integration_tests():
    """Run integration tests"""
    command = "python -m pytest tests/test_integration.py -v -m integration"
    return run_command(command, "Integration Tests")

def run_e2e_tests():
    """Run end-to-end tests"""
    command = "python -m pytest tests/test_e2e.py -v -m e2e"
    return run_command(command, "End-to-End Tests")

def run_performance_tests():
    """Run performance tests"""
    command = "python -m pytest tests/test_performance.py -v -m performance"
    return run_command(command, "Performance Tests")

def run_flutter_tests():
    """Run Flutter tests"""
    os.chdir("Flutter")
    command = "flutter test"
    success = run_command(command, "Flutter Widget Tests")
    os.chdir("..")
    return success

def run_all_tests():
    """Run all test suites"""
    print("🧪 Starting Comprehensive Test Suite")
    print("=" * 60)
    
    test_results = {}
    
    # Run unit tests
    test_results['unit'] = run_unit_tests()
    
    # Run integration tests
    test_results['integration'] = run_integration_tests()
    
    # Run E2E tests
    test_results['e2e'] = run_e2e_tests()
    
    # Run performance tests
    test_results['performance'] = run_performance_tests()
    
    # Run Flutter tests
    test_results['flutter'] = run_flutter_tests()
    
    # Print summary
    print(f"\n{'='*60}")
    print("TEST SUMMARY")
    print(f"{'='*60}")
    
    total_tests = len(test_results)
    passed_tests = sum(1 for success in test_results.values() if success)
    
    for test_type, success in test_results.items():
        status = "✅ PASSED" if success else "❌ FAILED"
        print(f"{test_type.upper():<15} {status}")
    
    print(f"\nOverall: {passed_tests}/{total_tests} test suites passed")
    
    if passed_tests == total_tests:
        print("🎉 All tests passed! Your application is ready for production.")
        return True
    else:
        print("⚠️  Some tests failed. Please review the output above.")
        return False

def run_smoke_tests():
    """Run smoke tests (quick validation)"""
    print("🔥 Running Smoke Tests")
    print("=" * 60)
    
    # Quick unit tests
    command = "python -m pytest tests/test_ultra_fast_api.py::TestHealthEndpoint::test_health_check_success -v"
    success = run_command(command, "Smoke Test - Health Check")
    
    if success:
        print("✅ Smoke tests passed!")
    else:
        print("❌ Smoke tests failed!")
    
    return success

def run_regression_tests():
    """Run regression tests"""
    print("🔄 Running Regression Tests")
    print("=" * 60)
    
    # Run specific regression tests
    command = "python -m pytest tests/test_performance.py::TestPerformanceRegression -v"
    success = run_command(command, "Regression Tests")
    
    if success:
        print("✅ Regression tests passed!")
    else:
        print("❌ Regression tests failed!")
    
    return success

def generate_test_report():
    """Generate comprehensive test report"""
    print("📊 Generating Test Report")
    print("=" * 60)
    
    # Generate coverage report
    command = "python -m pytest --cov=ultra_fast_api --cov=data_management_system --cov=performance_optimizer --cov-report=html:htmlcov --cov-report=xml --cov-report=term-missing"
    run_command(command, "Coverage Report Generation")
    
    # Generate test report
    command = "python -m pytest --html=test_report.html --self-contained-html"
    run_command(command, "HTML Test Report Generation")
    
    print("📁 Test reports generated:")
    print("  - htmlcov/index.html (Coverage report)")
    print("  - test_report.html (Test results)")
    print("  - coverage.xml (Coverage data)")

def main():
    """Main function"""
    parser = argparse.ArgumentParser(description="Crop Recommendation API Test Suite")
    parser.add_argument("--type", choices=["unit", "integration", "e2e", "performance", "flutter", "all", "smoke", "regression"], 
                       default="all", help="Type of tests to run")
    parser.add_argument("--report", action="store_true", help="Generate test report")
    parser.add_argument("--verbose", "-v", action="store_true", help="Verbose output")
    
    args = parser.parse_args()
    
    # Set working directory
    os.chdir(Path(__file__).parent)
    
    success = False
    
    if args.type == "unit":
        success = run_unit_tests()
    elif args.type == "integration":
        success = run_integration_tests()
    elif args.type == "e2e":
        success = run_e2e_tests()
    elif args.type == "performance":
        success = run_performance_tests()
    elif args.type == "flutter":
        success = run_flutter_tests()
    elif args.type == "smoke":
        success = run_smoke_tests()
    elif args.type == "regression":
        success = run_regression_tests()
    elif args.type == "all":
        success = run_all_tests()
    
    if args.report:
        generate_test_report()
    
    if success:
        print("\n🎉 Tests completed successfully!")
        sys.exit(0)
    else:
        print("\n❌ Tests failed!")
        sys.exit(1)

if __name__ == "__main__":
    main()
