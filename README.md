# VOLTHA Branch Difference Report Generator

This repository contains a tool, originally implemented by Zack Williams, that
identifies patchsets, by CHANGE-ID, that are not in both the `master` and
`voltha-2.1` branch of the VOLTHA repos. 

This tool can be used to help monitor patchset that have not been cherrypicked
between the branches.

There is an "exceptions.txt" file for each repository that holds the CHANGE-ID
for patchsets that differ between the branches, but have been "verified" as no
longer needed to be reported. This holds patchsets that were cherry picked with
different chabnge-IDs or for comments that represents a branch tagging for
example.

The script has one parameter, set via the environment: `UPDATE_GIT`. If the
value of this environment variable is `yes` then the script will `clone` the
repositories if nessisary and do a `git fetch --all` if the repository directory
already exists.
