package main

import (
	"bufio"
	"flag"
	"fmt"
	"os"
	"regexp"
	"strings"
)

var (
	prefixes = []string{
		// API Key.
		"aks_[0-9a-f]{20,}",
		// Cluster credentials password.
		"ccp_[0-9a-f]{20,}",
		// Session key secret.
		"sks_[0-9a-f]{20,}",
	}

	allowedKeys = map[string]struct{}{}
)

func main() {
	filesFlag := flag.String("files", "", "Comma-separated list of files to scan")
	flag.Parse()

	if *filesFlag == "" {
		fmt.Println("Usage: scanner -files=<comma-separated-files>")
		os.Exit(1)
	}

	var (
		files         = strings.Split(*filesFlag, ",")
		prefixPattern = strings.Join(prefixes, "|")
		regex         = regexp.MustCompile(prefixPattern)
	)

	hasIssues := false
	for _, file := range files {
		if file == "" {
			continue
		}

		f, err := os.Open(file)
		if err != nil {
			fmt.Printf("Error opening file %s: %v\n", file, err)
			os.Exit(1)
		}

		scanner := bufio.NewScanner(f)
		lineNumber := 1
		for scanner.Scan() {
			line := scanner.Text()
			matches := regex.FindAllString(line, -1)
			for _, match := range matches {
				if _, allowed := allowedKeys[match]; allowed {
					continue
				}

				fmt.Printf("Found illegal prefix (potential secret?) in %s at line %d: %s\n", file, lineNumber, line)
				hasIssues = true
			}
			lineNumber++
		}

		if err := scanner.Err(); err != nil {
			fmt.Printf("Error reading file %s: %v\n", file, err)
			if closeErr := f.Close(); closeErr != nil {
				fmt.Printf("Error closing file %s: %v\n", file, closeErr)
			}
			os.Exit(1)
		}

		if err := f.Close(); err != nil {
			fmt.Printf("Error closing file %s: %v\n", file, err)
			os.Exit(1)
		}
	}

	if hasIssues {
		fmt.Println("Illegal prefixes (potential secret?) found.")
		os.Exit(1)
	}
}
