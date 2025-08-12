#!/usr/bin/env python3
"""
Open-Meteo Self-Hosted Setup Script
==================================
Creates and manages a self-hosted Open-Meteo Docker container with weather data.
"""

import subprocess
import sys
import time
import json
import argparse
from typing import Dict, List, Optional
import requests


class OpenMeteoSetup:
    """Manages Open-Meteo Docker container setup and configuration."""
    
    def __init__(self, container_name: str = "openmeteo-api", port: int = 8080):
        self.container_name = container_name
        self.port = port
        self.image = "ghcr.io/open-meteo/open-meteo:latest"
        self.volume_name = f"{container_name}-data"
        
    def run_command(self, command: List[str], check: bool = True) -> subprocess.CompletedProcess:
        """Execute shell command with error handling."""
        try:
            result = subprocess.run(command, capture_output=True, text=True, check=check)
            return result
        except subprocess.CalledProcessError as e:
            print(f"Command failed: {' '.join(command)}")
            print(f"Error: {e.stderr}")
            if check:
                sys.exit(1)
            return e
    
    def check_docker(self) -> bool:
        """Verify Docker is installed and running."""
        try:
            result = self.run_command(["docker", "--version"])
            print(f"✓ Docker found: {result.stdout.strip()}")
            
            result = self.run_command(["docker", "info"], check=False)
            if result.returncode != 0:
                print("✗ Docker daemon not running")
                return False
            print("✓ Docker daemon running")
            return True
        except FileNotFoundError:
            print("✗ Docker not installed")
            return False
    
    def pull_image(self) -> None:
        """Pull latest Open-Meteo Docker image."""
        print(f"Pulling Open-Meteo image: {self.image}")
        self.run_command(["docker", "pull", self.image])
        print("✓ Image pulled successfully")
    
    def create_volume(self) -> None:
        """Create Docker volume for persistent data storage."""
        print(f"Creating volume: {self.volume_name}")
        self.run_command(["docker", "volume", "create", self.volume_name])
        print("✓ Volume created successfully")
    
    def stop_existing_container(self) -> None:
        """Stop and remove existing container if it exists."""
        result = self.run_command(["docker", "ps", "-a", "-q", "-f", f"name={self.container_name}"], check=False)
        if result.stdout.strip():
            print(f"Stopping existing container: {self.container_name}")
            self.run_command(["docker", "stop", self.container_name], check=False)
            self.run_command(["docker", "rm", self.container_name], check=False)
            print("✓ Existing container removed")
    
    def start_container(self) -> None:
        """Start Open-Meteo container."""
        print(f"Starting Open-Meteo container on port {self.port}")
        
        docker_cmd = [
            "docker", "run", "-d",
            "--name", self.container_name,
            "--restart", "unless-stopped",
            "-p", f"{self.port}:8080",
            "-v", f"{self.volume_name}:/app/data",
            "-e", "RUST_LOG=info",
            self.image
        ]
        
        self.run_command(docker_cmd)
        print("✓ Container started successfully")
    
    def wait_for_startup(self, timeout: int = 120) -> bool:
        """Wait for Open-Meteo API to become ready."""
        print("Waiting for Open-Meteo API to start...")
        
        for i in range(timeout):
            try:
                response = requests.get(f"http://localhost:{self.port}/v1/forecast?latitude=40.7&longitude=-74.0", timeout=5)
                if response.status_code == 200:
                    print("✓ Open-Meteo API is ready")
                    return True
            except requests.RequestException:
                pass
            
            if i % 10 == 0:
                print(f"  Waiting... ({i}/{timeout}s)")
            time.sleep(1)
        
        print("✗ API failed to start within timeout")
        return False
    
    def download_weather_data(self) -> None:
        """Download initial weather model data."""
        print("Downloading weather model data...")
        
        models = [
            ("ecmwf_ifs025", "ECMWF IFS 0.25°"),
            ("ncep_gfs025", "NOAA GFS 0.25°"),
            ("meteofrance_arpege_world025", "MeteoFrance ARPEGE World"),
        ]
        
        variables = "temperature_2m,relative_humidity_2m,pressure_msl,wind_speed_10m,wind_direction_10m,precipitation"
        
        for model, description in models:
            print(f"  Downloading {description}...")
            sync_cmd = [
                "docker", "run", "--rm",
                "-v", f"{self.volume_name}:/app/data",
                self.image,
                "sync", model, variables
            ]
            
            result = self.run_command(sync_cmd, check=False)
            if result.returncode == 0:
                print(f"  ✓ {description} downloaded")
            else:
                print(f"  ⚠ {description} download failed")
    
    def test_api(self) -> bool:
        """Test API functionality with sample requests."""
        print("Testing API functionality...")
        
        test_cases = [
            {
                "name": "Basic forecast",
                "url": f"http://localhost:{self.port}/v1/forecast?latitude=40.7&longitude=-74.0&hourly=temperature_2m"
            },
            {
                "name": "Multiple variables",
                "url": f"http://localhost:{self.port}/v1/forecast?latitude=51.5&longitude=-0.1&hourly=temperature_2m,pressure_msl,wind_speed_10m"
            }
        ]
        
        all_passed = True
        for test in test_cases:
            try:
                response = requests.get(test["url"], timeout=10)
                if response.status_code == 200:
                    data = response.json()
                    if "hourly" in data:
                        print(f"  ✓ {test['name']}")
                    else:
                        print(f"  ✗ {test['name']} - Invalid response format")
                        all_passed = False
                else:
                    print(f"  ✗ {test['name']} - HTTP {response.status_code}")
                    all_passed = False
            except Exception as e:
                print(f"  ✗ {test['name']} - {str(e)}")
                all_passed = False
        
        return all_passed
    
    def show_status(self) -> None:
        """Display container status and connection info."""
        result = self.run_command(["docker", "ps", "-f", f"name={self.container_name}"])
        print("\nContainer Status:")
        print(result.stdout)
        
        print(f"\nOpen-Meteo API URL: http://localhost:{self.port}")
        print(f"Test URL: http://localhost:{self.port}/v1/forecast?latitude=40.7&longitude=-74.0&hourly=temperature_2m")
        print(f"Documentation: https://open-meteo.com/en/docs")
    
    def setup(self, download_data: bool = True) -> None:
        """Complete setup process."""
        print("Open-Meteo Self-Hosted Setup")
        print("=" * 30)
        
        if not self.check_docker():
            print("Please install Docker and ensure it's running")
            sys.exit(1)
        
        self.pull_image()
        self.create_volume()
        self.stop_existing_container()
        self.start_container()
        
        if not self.wait_for_startup():
            print("Setup failed - container did not start properly")
            sys.exit(1)
        
        if download_data:
            self.download_weather_data()
            
            # Restart container to load new data
            print("Restarting container to load weather data...")
            self.run_command(["docker", "restart", self.container_name])
            if not self.wait_for_startup():
                print("Failed to restart after data download")
                sys.exit(1)
        
        if self.test_api():
            print("\n✓ Setup completed successfully!")
        else:
            print("\n⚠ Setup completed but API tests failed")
        
        self.show_status()


def main():
    parser = argparse.ArgumentParser(description="Setup self-hosted Open-Meteo Docker container")
    parser.add_argument("--container-name", default="openmeteo-api", help="Container name")
    parser.add_argument("--port", type=int, default=8080, help="Host port")
    parser.add_argument("--no-data", action="store_true", help="Skip downloading weather data")
    parser.add_argument("--test-only", action="store_true", help="Only test existing installation")
    
    args = parser.parse_args()
    
    setup = OpenMeteoSetup(container_name=args.container_name, port=args.port)
    
    if args.test_only:
        if setup.test_api():
            print("✓ API tests passed")
        else:
            print("✗ API tests failed")
            sys.exit(1)
    else:
        setup.setup(download_data=not args.no_data)


if __name__ == "__main__":
    main()