import os
import re

def fix_file(file_path, fixes):
    if not os.path.exists(file_path):
        print(f"File not found: {file_path}")
        return
    
    with open(file_path, 'r', encoding='utf-8') as f:
        lines = f.readlines()
        
    original = list(lines)
    
    # Process line replacements/deletions based on line numbers (1-indexed)
    for fix in fixes:
        line_idx = fix['line'] - 1
        if 0 <= line_idx < len(lines):
            action = fix['action']
            if action == 'delete_import':
                # only delete if it looks like an import
                if 'import' in lines[line_idx]:
                    lines[line_idx] = ''
            elif action == 'delete_line':
                # general line deletion (for unused vars warning when entire line is just assigning unused var)
                # Note: this might break if the line does more than just assigning an unused var.
                # Only use if we're sure it's safe.
                lines[line_idx] = f"// {lines[line_idx].lstrip()}"
            elif action == 'replace':
                lines[line_idx] = lines[line_idx].replace(fix['old'], fix['new'])
                
    if lines != original:
        with open(file_path, 'w', encoding='utf-8') as f:
            f.writelines(lines)
        print(f"Fixed: {file_path}")

fixes = {
    r"d:\BHASHALENS1\bhashalens_app\lib\main.dart": [
        {'line': 45, 'action': 'delete_import'}
    ],
    r"d:\BHASHALENS1\bhashalens_app\lib\models\conversation_message.dart": [
        {'line': 3, 'action': 'delete_import'}
    ],
    r"d:\BHASHALENS1\bhashalens_app\lib\pages\assistant_mode_page.dart": [
        {'line': 2, 'action': 'delete_import'},
        {'line': 105, 'action': 'delete_line'}
    ],
    r"d:\BHASHALENS1\bhashalens_app\lib\pages\camera_translate_page.dart": [
        {'line': 8, 'action': 'delete_import'}
    ],
    r"d:\BHASHALENS1\bhashalens_app\lib\pages\explain_mode_page.dart": [
        {'line': 130, 'action': 'delete_line'},
        {'line': 175, 'action': 'delete_line'},
        {'line': 253, 'action': 'delete_line'}
    ],
    r"d:\BHASHALENS1\bhashalens_app\lib\services\encrypted_local_storage_example.dart": [
        {'line': 11, 'action': 'delete_import'},
        {'line': 1, 'action': 'replace', 'old': '///', 'new': 'library encrypted_local_storage_example;\n///'} # Dangling library doc comment
    ],
    r"d:\BHASHALENS1\bhashalens_app\lib\services\smart_hybrid_router.dart": [
        {'line': 124, 'action': 'delete_line'}
    ],
    r"d:\BHASHALENS1\bhashalens_app\lib\services\tflite_translation_engine.dart": [
        {'line': 4, 'action': 'delete_import'},
        {'line': 313, 'action': 'delete_line'},
        {'line': 333, 'action': 'delete_line'}
    ],
    r"d:\BHASHALENS1\bhashalens_app\lib\services\translation_engine_example.dart": [
        {'line': 182, 'action': 'delete_line'},
        {'line': 66, 'action': 'replace', 'old': 'final', 'new': 'const'},
        {'line': 151, 'action': 'replace', 'old': 'padding:', 'new': 'padding: const'},
        {'line': 152, 'action': 'replace', 'old': 'EdgeInsets', 'new': 'const EdgeInsets'}
    ],
    r"d:\BHASHALENS1\bhashalens_app\lib\services\voice_translation_service.dart": [
        {'line': 14, 'action': 'delete_import'},
        {'line': 394, 'action': 'delete_line'}
    ]
}

if __name__ == "__main__":
    for file_path, file_fixes in fixes.items():
        fix_file(file_path, file_fixes)