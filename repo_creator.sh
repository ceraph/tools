#!/usr/bin/env bash

# WARNING: Entities at the root of the source directory will have 2 dots in import statement.

entity_postfix_length=2

source_dir=$1
dest_dir=$2


function remove_postfix_from_entity() {
	echo ${1::-$entity_postfix_length}
}

function repo_content() {
	local package=$1
	local entity_name=$2
	local entity_name_no_postfix=`remove_postfix_from_entity $entity_name`
	echo "$(cat <<DOC
package ch.ti8m.lukb.wadata.core.repositories.$package;

import ch.ti8m.lukb.wadata.core.domain.$package.$entity_name;
import org.springframework.data.repository.Repository;

public interface ${entity_name_no_postfix}Repository extends Repository<$entity_name, Long> {
}
DOC
)"
}

function convert_path_to_package {
	local path=$1
	local package=${path:2} # Remove ./
	local package=`echo $package | sed 's/\//./g'`
	echo "$package"
}

function create_repos() {
	local relative_path="$1"

	for file in "$relative_path"/*; do
		if [ -d "$file" ]; then
			mkdir -p "$dest_dir/$file"
			create_repos "$file"
		else
			local file_name=`basename $file`
			printf "Processing: $file_name"

			local entity_name=${file_name::-5} # Remove .java postfix
			local entity_name_no_postfix=`remove_postfix_from_entity $entity_name`
			printf " -> $entity_name_no_postfix\n"

			local package=`convert_path_to_package $relative_path`

			local file_content=$(repo_content "$package" $entity_name)
			echo "$file_content" > \
				"$dest_dir/$relative_path/${entity_name_no_postfix}Repository.java"
		fi
	done
}

printf "Source Dir:\n$source_dir\n"
printf "Dest Dir:\n$dest_dir\n"
echo ""

cd "$source_dir"
create_repos .
