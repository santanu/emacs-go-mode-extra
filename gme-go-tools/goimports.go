package main

import (
    "go/parser"
    "go/ast"
    "fmt"
    f "flag"
    "strings"
    "path"
)

var genhash *bool = f.Bool("h", false, "If true, produce list of 'import name' 'import path', else produce list of 'import path'")

func main () {
    f.Parse()
    ptree, _ := parser.ParseFile(f.Arg(0), nil, nil, 0)
    for _, l := range ptree.Decls {
        switch leaf := l.(type) {
        case *ast.GenDecl:
            for _, c := range leaf.Specs {
                switch cell:=c.(type) {
                case *ast.ImportSpec:
                    if *genhash {
                        if ident:=cell.Name; ident==nil {
                            _, pname:=path.Split(strings.Trim(string(cell.Path.Value), "\""))
                            fmt.Printf("\"%s\" %s\n", pname, cell.Path.Value)
                        } else {
                            fmt.Printf("\"%s\" %s\n", cell.Name, cell.Path.Value)
                        }
                    } else {
                        fmt.Printf("%s\n", cell.Path.Value)
                    }
                default: continue
                }
            }
        default:continue
        }
    }
}
