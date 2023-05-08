/*
 * Copyright (c) 2016
 *
 * Cristián Maureira-Fredes <cmaureirafredes@gmail.com>
 *
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1. Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright
 * notice, this list of conditions and the following disclaimer in the
 * documentation and/or other materials provided with the distribution.
 *
 * 3. The name of the author may not be used to endorse or promote
 * products derived from this software without specific prior written
 * permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS
 * OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
 * GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER
 * IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
 * OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN
 * IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 */
#include <map>
#include <set>
#include <getopt.h>
#include "OptionsParser.hpp"

/** Constructor which includes the options and requirements for the
 * command line interface
 */

OptionsParser::OptionsParser(int argc, char *argv[]) : argc_(argc), argv_(argv), integration_time(1.0f), interval_time(0.125f), gpus(0), snapshot_time(0.0f), softening(1e-4f), eta(0.01f), snapshot_number(0), length_output_number(0), resume(false), help(false)
{
  parse_command_line_arguments();
}

OptionsParser::~OptionsParser() {}

void OptionsParser::parse_command_line_arguments()
{
  // const char *const short_options = "hi:o:t:r:s:e:pz:l:ag:";
  const char *const short_options = "hi:o:t:r:s:e:pz:la";
  const struct option long_options[] = {
      {"help", no_argument, nullptr, 'h'},
      {"input", required_argument, nullptr, 'i'},
      {"output", required_argument, nullptr, 'o'},
      {"time", required_argument, nullptr, 't'},
      {"resume", required_argument, nullptr, 'r'},
      {"eta", required_argument, nullptr, 'e'},
      {"softening", required_argument, nullptr, 's'},
      {"interval", required_argument, nullptr, 'z'},
      {"lagrange", no_argument, nullptr, 'l'},
      {"all", no_argument, nullptr, 'a'},
      {"screen", no_argument, nullptr, 'p'},
      {nullptr, 0, nullptr, 0}};

  int option_index = 0;
  int c;
  ops.print_lagrange = false;
  ops.print_screen = false;
  ops.print_all = false;
  while ((c = getopt_long(argc_, argv_, short_options, long_options, &option_index)) != -1)
  {
    switch (c)
    {
    case 'h':
      help = true;
      break;
    case 'i':
      input_filename = optarg;
      break;
    case 'o':
      output_filename = optarg;
      break;
    case 't':
      integration_time = std::stof(optarg);
      break;
    case 'r':
      resume_filename = optarg;
      resume = true;
      break;
    case 's':
      softening = std::stof(optarg);
      break;
    case 'e':
      eta = std::stof(optarg);
      break;
    case 'z':
      interval_time = std::stof(optarg);
      break;
    case 'l':
      ops.print_lagrange = true;
      break;
    case 'p':
      ops.print_screen = true;
      break;
    case 'a':
      ops.print_all = true;
      break;
    case 'g':
      gpus = std::stoi(optarg);
      break;
    default:
      break;
    }
  }
}

/** Method that check if a file exist on the system */
// bool OptionsParser::file_exists(std::string filename)
// {
//   struct stat buffer;
//   if (stat(filename.c_str(), &buffer) != -1)
//   {
//     return true;
//   }
//   return false;
// }
bool OptionsParser::file_exists(std::string filename)
{
  std::ifstream file(filename.c_str());
  return file.good();
}

/** Method in charge to verify all the command-line arguments that where
 * used for the current run
 */
bool OptionsParser::check_options()
{
  // Check required options

  if (help)
  {
    std::cout << "Usage: " << argv_[0] << " [options]" << std::endl;
    std::cout << "TO BE UPDATED" << std::endl;
    return false;
  }

  if (resume)
  {
    if (resume_filename.empty())
    {
      std::cerr << "ERROR: Resume file is required!" << std::endl;
      return false;
    }
    if (!file_exists(resume_filename))
    {
      std::cerr << "ERROR: Resume file does not exist!" << std::endl;
      return false;
    }

    std::cerr << "Reading resume_filename: " << resume_filename << std::endl;
    // Open resume_filename
    std::ifstream rfile(resume_filename.c_str());
    std::string line, key, value;
    std::map<std::string, std::string> config_param;
    std::set<std::string> allowed_param;

    allowed_param.insert("NumberParticles");
    allowed_param.insert("Softening");
    allowed_param.insert("EtaTimestep");
    allowed_param.insert("IntegrationTime");
    allowed_param.insert("PrintScreen");
    allowed_param.insert("InputFilename");
    allowed_param.insert("OutputFilename");
    allowed_param.insert("SnapshotNumber");

    if (rfile.is_open())
    {
      while (getline(rfile, line))
      {
        // Extract the parameter name and value
        size_t pos = line.find(":");
        key = line.substr(0, pos);
        value = line.substr(pos + 1);

        // Remove any leading or trailing whitespace from the parameter name and value
        key.erase(0, key.find_first_not_of(" "));
        key.erase(key.find_last_not_of(" ") + 1);
        value.erase(0, value.find_first_not_of(" "));
        value.erase(value.find_last_not_of(" ") + 1);

        config_param[key] = value;
      }
    }
    // Closing resume file
    rfile.close();

    // Check is all the `key` are valid
    std::map<std::string, std::string>::iterator ii;
    for (ii = config_param.begin(); ii != config_param.end(); ii++)
    {
      if (allowed_param.find((*ii).first) != allowed_param.end())
      {
        std::cerr << (*ii).first << " -> " << (*ii).second << std::endl;
      }
      else
      {
        std::cerr << "Invalid param" << std::endl;
        std::cerr << "gravidy: Invalid option -- "
                  << (*ii).first
                  << " in the info file"
                  << std::endl;
        // std::cerr << desc << std::endl;
        return false;
      }
    }

    // Check if all the `value` of the `key` are valid

    // Checking time
    double config_time = strtod(config_param["IntegrationTime"].c_str(), NULL);
    if (config_time >= integration_time)
    {
      std::cerr << "gravidy: option requires an argument -- 'time'"
                << " greater than the one specifid in the info file"
                << std::endl;
      // std::cerr << desc << std::endl;
      return false;
    }
    else
    {
      snapshot_time = config_time;
    }

    // Checking softening
    softening = strtod(config_param["Softening"].c_str(), NULL);

    eta = strtod(config_param["EtaTimestep"].c_str(), NULL);

    // Checking PrintScreen
    // ops.print_screen = std::atoi(config_param["PrintScreen"].c_str());
    // read config_param["PrintScreen"] as bool
    ops.print_screen = (config_param["PrintScreen"] == "true") ? true : false;

    // check NumberParticles ?
    //  ...Check the number of lines
    //  ...TODO what if some particles are removed in the future?

    // check InputFilename
    // keep the same structure of the files.
    std::string InputFilename = config_param["InputFilename"];
    input_filename = InputFilename;
    std::ostringstream ss;
    ss << ".out";
    std::string ext(ss.str());
    output_filename = InputFilename + ext;

    // check OutputFilename
    std::string OutputFilename = config_param["OutputFilename"];

    // Checking snapshot number
    // snapshot_number = std::stoi(config_param["SnapshotNumber"].c_str()); // C++11
    snapshot_number = std::atoi(config_param["SnapshotNumber"].c_str());

    std::ostringstream s;
    s << std::setw(4) << std::setfill('0') << snapshot_number;
    std::string snap_name = OutputFilename + ".snapshot_" + s.str();

    if (!file_exists(snap_name))
    {
      std::cerr << "gravidy: cannot access "
                << snap_name
                << ": No such file or directory\n"
                << "(Check the OutputFilename and SnapshotNumber)"
                << std::endl;
      return false;
    }
    else
    {
      snapshot_filename = snap_name;
      // input_filename = snap_name;
    }
  }
  else // if the simulation is not being resume
  {
    // Check if input file is specified and exists
    if (input_filename.empty())
    {
      std::cerr << "ERROR: Input data file is required!" << std::endl;
      return false;
    }
    if (!file_exists(input_filename))
    {
      std::cerr << "ERROR: Input data file does not exist!" << std::endl;
      return false;
    }

    std::string ext = ".out";
    if (!output_filename.empty())
    {
      output_filename = output_filename + ext;
    }
    else
    {
      output_filename = input_filename + ext;
    }
  }

  // check eta is non-negative
  if (eta < 0)
  {
    std::cerr << "ERROR: ETA parameter must be non-negative!" << std::endl;
    return false;
  }

  // Checking softening
  if (softening < 0)
  {
    std::cerr << "ERROR: Softening parameter must be non-negative!" << std::endl;
    return false;
  }

  // check interval is non-negative
  if (interval_time < 0)
  {
    std::cerr << "ERROR: Output time interval must be non-negative!" << std::endl;
    return false;
  }

  // gpus must be non-negative and even
  if (gpus < 0)
  {
    std::cerr << "ERROR: Number of GPUs must be non-negative!" << std::endl;
    return false;
  }
  if (gpus % 2 != 0)
  {
    std::cerr << "ERROR: Number of GPUs must be even!" << std::endl;
    return false;
  }

  // Checking frequency of snapshots and integration time
  // to know how many snapshots will be written.
  unsigned int tmp = (unsigned int)(integration_time / interval_time);
  do
  {
    ++length_output_number;
    tmp /= 10;
  } while (tmp);
  length_output_number += 1;

  return true;
}

void OptionsParser::print()
{
  // OptionsParser parser(argc, argv);

  // TODO: Use the parsed options

  std::cout << "Simulation parameters:\n";
  std::cout << "input_filename: " << input_filename << "\n";
  std::cout << "output_filename: " << output_filename << "\n";
  std::cout << "integration_time: " << integration_time << "\n";
  std::cout << "resume_filename: " << resume_filename << "\n";
  std::cout << "resume: " << resume << "\n";
  std::cout << "snapshot_filename: " << snapshot_filename << "\n";
  std::cout << "snapshot_number: " << snapshot_number << "\n";
  std::cout << "eta: " << eta << "\n";
  std::cout << "softening: " << softening << "\n";
  std::cout << "interval_time: " << interval_time << "\n";
  std::cout << "length_output_number: " << length_output_number << "\n";
  std::cout << "print_lagrange: " << ops.print_lagrange << "\n";
  std::cout << "print_all: " << ops.print_all << "\n";
  std::cout << "print_screen: " << ops.print_screen << "\n";
  std::cout << "gpus: " << gpus << "\n";
  std::cout << "help: " << help << "\n";
}
