using MlxtranTypst
using Test

const M = MlxtranTypst

@testset "MlxtranTypst" begin
    @testset "operator precedence" begin
        @test M.mlxtran_to_typst("EQUATION:\ny = a + b*c") == "\$y = a + b dot c\$"
        @test M.mlxtran_to_typst("EQUATION:\ny = 10^a^b*c") == "\$y = 10^(a^(b)) dot c\$"
        @test M.mlxtran_to_typst("EQUATION:\nz = -(a - b)") == "\$z = -(a - b)\$"
    end

    @testset "ode derivative" begin
        @test M.mlxtran_to_typst("EQUATION:\nddt_I = beta*T*I - dI*I") ==
              "\$(dif I)/(dif t) = beta dot T dot I - \"dI\" dot I\$"
    end

    @testset "calls and power" begin
        @test M.mlxtran_to_typst("EQUATION:\ny = log10(max((r*I*2), 0.001)) + 10^(T0)") ==
              "\$y = log_10(max(r dot I dot 2, 0.001)) + 10^(\"T0\")\$"
    end

    @testset "identifier prettification" begin
        @test M.mlxtran_to_typst("EQUATION:\nT_0 = 1") == "\$T_0 = 1\$"
        @test M.mlxtran_to_typst("EQUATION:\nbeta_prime_exp = 1") == "\$beta_(\"prime,exp\") = 1\$"
        @test M.mlxtran_to_typst("EQUATION:\nlambda = 1") == "\$lambda = 1\$"
    end

    @testset "camelcase greek peeling" begin
        @test M.mlxtran_to_typst("EQUATION:\nalphaE = 1") == "\$alpha_E = 1\$"
        @test M.mlxtran_to_typst("EQUATION:\nthetaE = 1") == "\$theta_E = 1\$"
        @test M.mlxtran_to_typst("EQUATION:\nlambdaEstr = 1") == "\$lambda_(\"Estr\") = 1\$"
        @test M.mlxtran_to_typst("EQUATION:\nomega1 = 1") == "\$omega_1 = 1\$"
        # a lowercase suffix is not a camelCase boundary: no false peel
        @test M.mlxtran_to_typst("EQUATION:\nbetas = 1") == "\$\"betas\" = 1\$"
    end

    @testset "division and greek subscript" begin
        @test M.mlxtran_to_typst("EQUATION:\ny = a/(theta_E + I)") ==
              "\$y = (a)/(theta_E + I)\$"
    end

    @testset "multiple equations" begin
        src = "EQUATION:\ny = a + b\nddt_x = -k*x"
        @test M.mlxtran_to_typst(src) == "\$y = a + b\$\n\$(dif x)/(dif t) = -k dot x\$"
    end

    @testset "scientific notation" begin
        @test M.mlxtran_to_typst("EQUATION:\nk = 1.5e-6*C") ==
              "\$k = 1.5 times 10^(-6) dot C\$"
        @test M.mlxtran_to_typst("EQUATION:\nk = 1e-6") == "\$k = 10^(-6)\$"
        @test M.mlxtran_to_typst("EQUATION:\nk = 2.3E+4") == "\$k = 2.3 times 10^(4)\$"
    end

    @testset "keyword arguments" begin
        @test M.mlxtran_to_typst("PK:\ncompartment(cmt = 1, volume = V)") ==
              "\$\"compartment\"(\"cmt\" = 1, \"volume\" = V)\$"
        @test M.mlxtran_to_typst("PK:\ndepot(target = A)") == "\$\"depot\"(\"target\" = A)\$"
    end

    @testset "conditional cases" begin
        @test M.mlxtran_to_typst("EQUATION:\nif abs(a-b) < c\nx = 0\nelse\nx = a-b\nend") ==
              "\$x = cases(0 & \"if\" abs(a - b) < c, a - b & \"otherwise\")\$"
        @test M.mlxtran_to_typst("EQUATION:\nif p == 0\ny = 1\nelseif p == 1\ny = 2\nelse\ny = 3\nend") ==
              "\$y = cases(1 & \"if\" p = 0, 2 & \"if\" p = 1, 3 & \"otherwise\")\$"
        @test M.mlxtran_to_typst("EQUATION:\nif s != 0\na = 1\nb = 2\nelse\na = 3\nb = 4\nend") ==
              "\$a = cases(1 & \"if\" s eq.not 0, 3 & \"otherwise\")\$\n" *
              "\$b = cases(2 & \"if\" s eq.not 0, 4 & \"otherwise\")\$"
        @test M.mlxtran_to_typst("EQUATION:\nif u > 0\nif v > 0\nw = 1\nelse\nw = 2\nend\nelse\nw = 3\nend") ==
              "\$w = cases(1 & \"if\" u > 0 \"and\" v > 0, 2 & \"if\" u > 0 \"and\" not (v > 0), 3 & \"otherwise\")\$"
        @test M.mlxtran_to_typst("EQUATION:\nif a > 0\nif b > 0\nx = 1\nelseif c > 0\nx = 2\nelse\nx = 3\nend\nend") ==
              "\$x = cases(1 & \"if\" a > 0 \"and\" b > 0, 2 & \"if\" a > 0 \"and\" c > 0, " *
              "3 & \"if\" a > 0 \"and\" not (b > 0) \"and\" not (c > 0))\$"
    end

    @testset "extended functions" begin
        @test M.mlxtran_to_typst("EQUATION:\ny = sqrt(x) + tanh(z) + floor(w)") ==
              "\$y = sqrt(x) + tanh(z) + floor(w)\$"
        @test M.mlxtran_to_typst("EQUATION:\ny = logit(p)") == "\$y = \"logit\"(p)\$"
    end
end
