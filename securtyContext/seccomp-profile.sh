#!/bin/bash
strace_file=$@

# Get and sort the syscalls
perl -lne 'print $1 if /([a-zA-Z_]+\()/' "$strace_file" | sort -u > $strace_file-syscalls
input=$(readlink -f $strace_file-syscalls)
syscalls=()
while IFS= read -r line
do
    echo ${line%(}
    syscalls+=( ${line%(} )
done < $input
unset IFS
    
tmpfile=$(mktemp /tmp/seccomp-$strace_file.XXXXXX)


# start the seccomp profile
cat <<-EOF > "$tmpfile"
{
    "defaultAction": "SCMP_ACT_ERRNO",
	"architectures": [
        "SCMP_ARCH_X86_64",
        "SCMP_ARCH_X86",
        "SCMP_ARCH_X32"
    ],
    "syscalls": [
        {
            "names": [
	EOF

	for syscall in "${syscalls[@]}"; do
        cat <<-EOF
			    "${syscall}",
		EOF
	done >> "$tmpfile"

	# remove trailing comma
	sed -i '$s/,$//' "$tmpfile"

	cat <<-EOF >> "$tmpfile"
	        ],
            "action": "SCMP_ACT_ALLOW",
        }
    ]
}
EOF
cat "$tmpfile"